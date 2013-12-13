readline = require("readline")
LinkSequenceBuilder = require("./link").LinkSequenceBuilder
LinkSequenceDecoder = require("./link").LinkSequenceDecoder

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
      sequence.addPayloadMD5 magnet
      sequence.addPayloadSHA1 magnet
      sequence.addPayloadSHA256 magnet
      sequence.addOriginalCreationDate new Date()
      sequence.addLastModifiedDate new Date()
      addresses = sequence.getAddresses 14
      for x of addresses
        console.log addresses[x]
      decoder = new LinkSequenceDecoder(addresses)
      errors = decoder.verify()
      if errors.length > 0
        console.log error for error in errors
      console.log decoder.payloadInline
      console.log decoder.name
      console.log decoder.keywords
      console.log decoder.originalCreationDate
      console.log decoder.lastModifiedDate
      rl.close()