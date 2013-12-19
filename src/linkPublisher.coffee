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
    (addresses.length * 0.002) + (addresses.length * 0.00000001)
      
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
        useable = tx if tx.amount >= total
      callback("No unspent") unless useable?
      outs[useable.address] = useable.amount - total
      client.createRawTransaction [useable], outs, (err, rawtx)->
        client.decodeRawTransaction rawtx, (error, decoded)->
          client.signRawTransaction decoded, [useable], (error, decoded) ->
            console.log error, decoded
            client.sendRawTransaction decoded.hex, (error, result) ->
              callback(result) if callback?

exports.LinkPublisher = LinkPublisher
