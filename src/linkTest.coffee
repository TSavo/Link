readline = require("readline")
LinkSequenceBuilder = require("./link").LinkSequenceBuilder
LinkSequenceDecoder = require("./link").LinkSequenceDecoder
bitcoin = require "bitcoin"
client = new bitcoin.Client
  host: 'localhost'
  port: 8332
  user: 'Kevlar'
  pass: 'zabbas'


rl = readline.createInterface(
  input: process.stdin
  output: process.stdout
)
rl.question "Payload: ", (magnet) ->
  rl.question "Name: ", (name) ->
    rl.question "Keywords: ", (keywords) ->
      sequence = new LinkSequenceBuilder()
      sequence.addPayloadInline magnet
      sequence.addName name
      sequence.addKeywords keywords
      #sequence.addPayloadMD5 magnet
      #sequence.addPayloadSHA1 magnet
      #sequence.addPayloadSHA256 magnet
      #sequence.addOriginalCreationDate new Date()
      #sequence.addLastModifiedDate new Date()
      addresses = sequence.getAddresses 14
      decoder = new LinkSequenceDecoder(addresses)
      errors = decoder.verify()
      if errors.length > 0
        console.log error for error in errors
      console.log decoder.payloadInline
      console.log decoder.name
      console.log decoder.keywords
      #console.log decoder.originalCreationDate
      #console.log decoder.lastModifiedDate
      
      @outs = {}
      for x in addresses
        @outs[x] = 0.00000001
      
      total = addresses.length * 0.00000001
      client.listUnspent 0, (err, unspent) ->
        @useable = undefined
        for tx in unspent
          @useable = tx if tx.amount > 0
          return console.log "No unspent" unless useable?
        console.log @useable.amount
        outs[@useable.address] = @useable.amount - total
        client.createRawTransaction [@useable], @outs, (err, rawtx)->
          console.log "rawtx: " + rawtx
          client.decodeRawTransaction rawtx, (error, decoded)->
            console.log JSON.stringify decoded
            client.signRawTransaction rawtx, [@useable], (error, decoded) ->
              console.log decoded
              client.sendRawTransaction decoded.hex, (error, result) ->
                console.log result
      rl.close()