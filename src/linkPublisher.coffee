LinkSequenceBuilder = require("./link").LinkSequenceBuilder

class LinkPublisher
  constructor:(client)->
    @client = client
  publish: (message, callback) ->
    sequence = new LinkSequenceBuilder(@client.opts.version)
    sequence.addPayloadInline message.payloadInline if message.payloadInline?
    sequence.addName message.name if message.name?
    sequence.addKeywords message.keywords if message.keywords?
    sequence.addDescription message.description if message.description?
    sequence.addOriginalCreationDate message.originalCreationDate if message.originalCreationDate?
    sequence.addLastModifiedDate message.lastModifiedDate if message.lastModifiedDate?
    addresses = sequence.getAddresses()
    client = @client
    outs = {}
    for x in addresses
      outs[x] = 0.00000001
    fee = addresses.length * 0.002
    total = (addresses.length * 0.00000001) + fee
    client.listUnspent 0, (err, unspent) ->
      useable = undefined
      for tx in unspent
        useable = tx if tx.amount > 0
        return console.log "No unspent" unless useable?
      outs[useable.address] = useable.amount - total
      client.createRawTransaction [useable], outs, (err, rawtx)->
        client.decodeRawTransaction rawtx, (error, decoded)->
          client.signRawTransaction rawtx, [useable], (error, decoded) ->
            client.sendRawTransaction decoded.hex, (error, result) ->
              callback(result) if callback?

exports.LinkPublisher = LinkPublisher