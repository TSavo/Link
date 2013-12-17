readline = require("readline")
LinkPublisher = require("./linkPublisher").LinkPublisher
bitcoin = require "bitcoin"
client = new bitcoin.Client
  host: 'localhost'
  port: 8332
  user: 'Kevlar'
  pass: 'zabbas'
client.version=14

rl = readline.createInterface
  input: process.stdin
  output: process.stdout

rl.question "Payload: ", (magnet) ->
  rl.question "Name: ", (name) ->
    rl.question "Keywords: ", (keywords) ->
      publisher = new LinkPublisher client
      publisher.publish
        payloadInline:magnet
        name:name
        keywords:keywords
      , console.log
      rl.close()
