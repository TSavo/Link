LinkSequenceBuilder = require("./link").LinkSequenceBuilder

class LinkPublisher
  constructor:(client)->
    @client = client
    
  encodeAddresses: (message)->
    sequence = new LinkSequenceBuilder(@client.version)
    sequence.addPayloadInline message.payloadInline if message.payloadInline?
    sequence.addName message.name if message.name?
    sequence.addKeywords message.keywords if message.keywords?
    sequence.addDescription message.description if message.description?
    sequence.addOriginalCreationDate message.originalCreationDate if message.originalCreationDate?
    sequence.addLastModifiedDate message.lastModifiedDate if message.lastModifiedDate?
    sequence.addLicense message.license if message.license?
    sequence.getAddresses()
 
  getMessageCost: (addresses)->
    ((addresses.length * 0.02) + (addresses.length * 0.00000001)).toFixed(8)
      
  publish: (message, callback) ->
    addresses = @encodeAddresses message
    total = @getMessageCost addresses
    client = @client
    outs = {}
    for x in addresses
      outs[x] = 0.00000001
    client.listUnspent 0, (err, unspent) ->
      useable = undefined
      for tx in unspent
        useable = tx if tx.amount.toFixed(8) >= total.toFixed(8) && (!useable? || useable.amount.toFixed(8) > tx.amount.toFixed(8))
      return callback("No unspent") unless useable?
      outs[useable.address] = useable.amount.toFixed(8) - total.toFixed(8) if useable.amount.toFixed(8) > total.toFixed(8)
      client.createRawTransaction [useable], outs, (err, rawtx)->
        client.decodeRawTransaction rawtx, (error, decoded)->
          client.signRawTransaction rawtx, [useable], (error, decoded) ->
            client.sendRawTransaction decoded.hex, (error, result) ->
              callback(result) if callback?

exports.LinkPublisher = LinkPublisher
