levelup = require 'levelup'
ThreadBarrier = require('./concurrent').ThreadBarrier
decodeBase58 = require('./link').decodeBase58
bytesToHex = require('./link').bytesToHex
hashBuffer = require('./link').hashBuffer
WritableBufferStream = require('buffertools').WritableBufferStream
LinkSequenceDecoder = require("./link").LinkSequenceDecoder


startBufferStream = new WritableBufferStream()
startBufferStream.write "Link"
startBuffer = startBufferStream.getBuffer()
      
decoder = new LinkSequenceDecoder

decodeTx = (tx, db)->
  spends = []
  for spend in tx.vout
    if spend.value == 1e-8
      for address in spend.scriptPubKey.addresses
        spends.push address
  decoded = decoder.decode spends
  errors = decoder.verify decoded
  if errors.length > 0
    console.log error for error in errors
    return
  id = hashBuffer("sha256", new Buffer(JSON.stringify decoded)).toString("hex")
  db.put id, decoded


nextBlock = (blockIndex, db, client, callback)->
  console.log("Still indexing: " + blockIndex) if blockIndex % 1000 == 0
  client.getBlockHash blockIndex, (error, hash) ->
    client.getBlock hash, (error, block)->
      if error? then return callback blockIndex
      if block?.tx?
        do (blockIndex) ->
          tb = new ThreadBarrier block.tx.length, ()->
            nextBlock blockIndex+1, db, client, callback
          for tx in block.tx
            client.getRawTransaction tx, (err, raw) ->
              client.decodeRawTransaction raw, (error, tx)->
                for vout in tx.vout
                  if vout.scriptPubKey?.addresses?
                    for address in vout.scriptPubKey.addresses
                      data = bytesToHex decodeBase58 address
                      linkStart = data.substring 2, 10
                      b = new Buffer linkStart, "hex"
                      if b.compare(startBuffer) == 0
      	                decodeTx tx, db
      	                continue
      	        tb.join()
      else
        nextBlock blockIndex+1, db, client, callback   

getLatest = (db, client)->
  db.get "lastBlock", (err, lastBlock)->
    if err then lastBlock = 128100
    console.log "Starting indexing: " + lastBlock
    nextBlock lastBlock, db, client, (lastBlock)->
      db.put "lastBlock", lastBlock
      console.log "Finished indexing: " + lastBlock
      setTimeout ()->
        getLatest(db, client)
      , 60000

dbMap = {}
getDB = (name, client)->
  if dbMap[name]? then return dbMap[name]
  db = levelup("LinkDB-" + name, {valueEncoding: 'json'})
  require("./search").search(db)
  getLatest(db, client)
  dbMap[name] = db
      
exports.db = getDB