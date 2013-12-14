bitcoin = require "bitcoin"
require 'buffertools'
decodeBase58 = require('./link').decodeBase58
bytesToHex = require('./link').bytesToHex
WritableBufferStream = require('buffertools').WritableBufferStream
LinkSequenceDecoder = require("./link").LinkSequenceDecoder
client = new bitcoin.Client
  host: 'localhost'
  port: 8332
  user: 'Kevlar'
  pass: 'zabbas'
versionBuffer = new Buffer 1
versionBuffer.fill 14
startBufferStream = new WritableBufferStream()
startBufferStream.write versionBuffer
startBufferStream.write "Link"
startBuffer = startBufferStream.getBuffer()
	  
class ThreadBarrier
  constructor: (@parties, @block) ->
  join: ->
    --@parties
    if @parties < 1
      @block()
    
decodeTx = (tx)->
  spends = []
  for spend in tx.vout
    if spend.value == 1e-8
      for address in spend.scriptPubKey.addresses
        spends.push address
  console.log spends
  decoder = new LinkSequenceDecoder(spends)
  errors = decoder.verify()
  if errors.length > 0
    console.log error for error in errors
  console.log decoder.payloadInline
  console.log decoder.name
  console.log decoder.keywords
  
x = 128100;
nextBlock = (blockIndex)->
  client.getBlockHash blockIndex, (error, hash) ->
    client.getBlock hash, (error, block)->
      if block.tx?
        do (blockIndex) ->
          tb = new ThreadBarrier block.tx.length, ()->
            nextBlock blockIndex+1
          for tx in block.tx
            client.getRawTransaction tx, (err, raw) ->
      	      client.decodeRawTransaction raw, (error, tx)->
      	        for vout in tx.vout
      	          if vout.scriptPubKey?.addresses?
      	            for address in vout.scriptPubKey.addresses
                      data = bytesToHex decodeBase58 address
                      linkStart = data.substring 0, 10
                      b = new Buffer linkStart, "hex"
                      if b.compare(startBuffer) == 0
      	                decodeTx tx
      	        tb.join()
      else
        nextBlock(blockIndex+1)
      	                
	
nextBlock(x)
    