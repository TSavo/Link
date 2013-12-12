crypto = require("crypto")
BigInteger = require("./jsbn.js")

nbi = ->
  new BigInteger(null)
nbv = (i) ->
  r = nbi()
  r.fromInt i
  r

hexToBytes = (hex) ->
  bytes = []
  c = 0

  while c < hex.length
    bytes.push parseInt(hex.substr(c, 2), 16)
    c += 2
  bytes

bytesToHex = (bytes) ->
  hex = []
  i = 0

  while i < bytes.length
    hex.push (bytes[i] >>> 4).toString(16)
    hex.push (bytes[i] & 0xF).toString(16)
    i++
  hex.join ""

encodeBase58 = (input) ->
  bi = BigInteger.fromByteArrayUnsigned(input)
  chars = []
  while bi.compareTo(base) >= 0
    mod = bi.mod(base)
    chars.unshift alphabet[mod.intValue()]
    bi = bi.subtract(mod).divide(base)
  chars.unshift alphabet[bi.intValue()]
  i = 0
  while i < input.length
    if input[i] is 0x00
      chars.unshift alphabet[0]
    else
      break
    i++
  chars.join ""
  
decodeBase58 = (input) ->
  bi = BigInteger.valueOf(0)
  leadingZerosNum = 0
  i = input.length - 1

  while i >= 0
    alphaIndex = alphabet.indexOf(input[i])
    throw "Invalid character"  if alphaIndex < 0
    bi = bi.add(BigInteger.valueOf(alphaIndex).multiply(base.pow(input.length - 1 - i)))
    
    # This counts leading zero bytes
    if input[i] is "1"
      leadingZerosNum++
    else
      leadingZerosNum = 0
    i--
  bytes = bi.toByteArrayUnsigned()
  
  # Add leading zeros
  bytes.unshift 0  while leadingZerosNum-- > 0
  bytes
  
makeAddress = (addressBuffer) ->
  base58 hexToBytes(addressBuffer.toString("hex"))
encodeAddress = (buf, version) ->
  version = version or 0x00
  padding = new Buffer(21) # version byte + 20 bytes = 21
  padding.fill version # fill with version
  buf.copy padding, 1, 0 # start a 1 to leave version byte at start
  sha = crypto.createHash("sha256")
  sha.update padding # first round of sha
  once = sha.digest()
  sha = crypto.createHash("sha256")
  sha.update once # second round of sha
  twice = sha.digest()
  fin = new Buffer(25) # version byte + 20 bytes + 4 byte checksum = 25
  padding.copy fin
  twice.copy fin, 21 # checksum starts at 21 which is version byte + 20 bytes
  encodeBase58 hexToBytes(fin.toString("hex"))
encodeAddresses = (buf, version) ->
  version = version or 0x00
  result = []
  x = 0 # for every group of 20

  while x < buf.length
    # bytes
    next = buf.slice(x, x + 20) # get the next 20 bytes
    result.push encodeAddress(next, version)
    x = x + 20
  result
  
startSequenceOpCode = "4c696e6b"
inlinePayloadOpCode = "01"
attachmentPayloadOpCode = "02"
mimeTypeOpCode = "03"
payloadEncodingOpCode = "04"
payloadMD5OpCode = "05"
payloadSHA1OpCode = "06"
payloadSHA256OpCode = "07"

nameOpCode = "10"
descriptionOpCode = "11"
keywordsOpCode = "12"
uriOpCode = "13"
filenameOpCode = "14"
originalCreationDateOpCode = "15"
lastModifiedDateOpCode = "16"
referencesTransactionOpCode = "F1"
replacesTransactionOpCode = "F2"
nextTransactionOpCode = "FF"
	
endSequence = "00"
  
encodeBuffer = (buf) ->
  decimalToHex(buf.length, 4) + buf.toString("hex");
encodeString = (str) ->
  encodeBuffer(new Buffer(str))
encodePayloadInline = (str) ->
  inlinePayloadOpCode + encodeString(str)
encodePayloadAttachment = (buf) ->
  attachmentPayloadOpCode + encodeBuffer(buf)
encodePayloadEncoding = (str) ->
  payloadEncodingOpCode + encodeString(str)
encodePayloadMD5Buffer = (buf) ->
  hash = crypto.createHash("md5")
  hash.update buf
  v = hash.digest().toString("hex")
  console.log v.length
  payloadMD5OpCode + v
encodePayloadSHA1Buffer = (buf) ->
  hash = crypto.createHash("sha1")
  hash.update buf
  payloadSHA1OpCode + hash.digest().toString("hex")
encodePayloadSHA256Buffer = (buf) ->
  hash = crypto.createHash("sha256")
  hash.update buf
  payloadSHA256OpCode + hash.digest().toString("hex")
encodeName = (str) ->
  nameOpCode + encodeString(str)
encodeDescription = (str) ->
  descriptionOpCode + encodeString(str)
encodeURI = (str) ->
  uriOpCode + encodeString(str)
encodeFilename = (str) ->
  filenameOpCode + encodeString(str)
encodeKeywords = (str) ->
  keywordsOpCode + encodeString(str)
encodeMimeType = (str) ->
  mimeTypeOpCode + encodeString(str)

decodeSize = (buffer, ip) ->
  parseInt decodeBytes(buffer, ip, 2)[1].toString("hex"), 16
decodeString = (buffer, ip) ->
  size = decodeSize(buffer, ip)
  [size + 2, decodeBytes(buffer, ip + 2, size)[1].toString("utf-8")]
decodeBuffer = (buffer, ip) ->
  size = decodeSize(buffer, ip)
  [size + 2, decodeBytes(buffer, ip+2, size)[1]]
decodeBytes = (buffer, ip, length) ->
  p = new Buffer(length)
  buffer.copy p, 0, ip
  [length, p]
decimalToHex = (d, padding) ->
  hex = Number(d).toString(16)
  padding = (if typeof (padding) is "undefined" or padding is null then 2 else padding)
  hex = "0" + hex  while hex.length < padding
  hex

alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
BigInteger.valueOf = nbv
base = BigInteger.valueOf(58)
BigInteger.fromByteArrayUnsigned = (ba) ->
  unless ba.length
    ba.valueOf 0
  else if ba[0] & 0x80
    new BigInteger([0].concat(ba))
  else
    new BigInteger(ba)

BigInteger::toByteArrayUnsigned = ->
  ba = @abs().toByteArray()
  if ba.length
    ba = ba.slice(1)  if ba[0] is 0
    ba.map (v) ->
      (if (v < 0) then v + 256 else v)
  else
    ba



	
class LinkSequenceBuilder
  str: startSequenceOpCode
  toString: ->
    @str + endSequence
  addName: (name) ->
    @str += encodeName(name)
  addDescription: (description) ->
    @str += encodeDescription description
  addURI: (uri) ->
    @str += encodeURI uri
  addFilename: (filename) ->
    @str += encodeFilename filename
  addMimeType: (mimeType) ->
    @str += encodeMimeType mimeType
  addKeywords: (keywords) ->
    @str += encodeKeywords(keywords)
  addPayloadInline: (payload) ->
    @str += encodePayloadInline payload
  addPayloadAttachment: (buf) ->
    @str += encodePayloadAttachment buf
  addPayloadMD5: (buf) ->
    @str += encodePayloadMD5Buffer buf
  addPayloadSHA1: (buf) ->
    @str += encodePayloadSHA1Buffer buf
  addPayloadSHA256: (buf) ->
    @str += encodePayloadSHA256Buffer buf

class LinkSequenceDecoder
  constructor: (@sequence) ->
    startSequence= new Buffer(4)
    sequence.copy startSequence
    firstFour = startSequence.toString("utf-8")
    throw new Exception("First 4 bytes were: " + firstFour)  unless firstFour is "Link"
    ip = 4
    running = true
    while running 
      nextOp = new Buffer(1)
      sequence.copy nextOp, 0, ip
      op = nextOp.toString("hex")
      console.log op
      ip++
      switch op
        when inlinePayloadOpCode
          payload = decodeString(sequence, ip)
          ip += payload[0]
          @payloadInline = payload[1]
        when nameOpCode
          payload = decodeString(sequence, ip)
          ip += payload[0]
          @name = payload[1]
        when keywordsOpCode
          payload = decodeString(sequence, ip)
          ip += payload[0]
          @keywords = payload[1]
        when descriptionOpCode
          payload = decodeString(sequence, ip)
          ip += payload[0]
          @description = payload[1]
        when uriOpCode
          payload = decodeString(sequence, ip)
          ip += payload[0]
          @URI = payload[1]
        when filenameOpCode
          payload = decodeString(sequence, ip)
          ip += payload[0]
          @filename = payload[1]
        when attachmentPayloadOpCode
          payload = decodeBuffer(sequence, ip)
          ip += payload[0]
          @payloadAttachment = payload[1]
        when payloadMD5OpCode
          payload = decodeBytes(sequence, ip, 16)
          ip += payload[0]
          @payloadMD5 = payload[1].toString("hex")
        when payloadSHA1OpCode
          payload = decodeBytes(sequence, ip, 20)
          ip += payload[0]
          @payloadSHA1 = payload[1].toString("hex")
        when payloadSHA256OpCode
          payload = decodeBytes(sequence, ip, 32)
          ip += payload[0]
          @payloadSHA256 = payload[1].toString("hex")
        when endSequence
          running = false
  verify: ->
    errors = []
    p = @payloadAttachment
    if not p then p = @payloadInline
    if not p? then return
    if @payloadMD5?
      h = hashBuffer "md5", p
      if(h != @payloadMD5)
        errors.push("Expected MD5 was #{@payloadMD5} but the payload MD5 is #{h}")
    if @payloadSHA1?
      h = hashBuffer "sha1", p
      if(h != @payloadSHA1)
        errors.push("Expected SHA-1 was #{@payloadSHA1} but the payload SHA-1 is #{h}")
    if @payloadSHA256?
      h = hashBuffer "sha256", p
      if(h != @payloadSHA256)
        errors.push("Expected SHA-256 was #{@payloadSHA256} but the payload SHA-256 is #{h}")
    errors       
    
hashBuffer = (algo, buffer) ->
  hash = crypto.createHash algo
  hash.update buffer
  return hash.digest().toString("hex")
  
    

fs = require("fs")
readline = require("readline")
rl = readline.createInterface(
  input: process.stdin
  output: process.stdout
)
rl.question "What is the magnet link? ", (magnet) ->
  rl.question "What is the name?", (name) ->
    rl.question "Keywords?", (keywords) ->
      sequence = new LinkSequenceBuilder()
      sequence.addPayloadInline magnet
      sequence.addName name
      sequence.addKeywords keywords
      sequence.addPayloadMD5 magnet
      sequence.addPayloadSHA1 magnet
      sequence.addPayloadSHA256 magnet
      buf = new Buffer(sequence.toString(), "hex")
      addresses = encodeAddresses(buf, 14)
      decodedBuf = new Buffer(addresses.length * 20)
      decodedBuf.fill 0x00
      for x of addresses
        console.log addresses[x]
        new Buffer(bytesToHex(decodeBase58(addresses[x]).slice(1)), "hex").copy decodedBuf, x * 20
      console.log decodedBuf.toString("hex")
      decoder = new LinkSequenceDecoder(decodedBuf)
      errors = decoder.verify()
      if errors.length > 0
        console.log error for error in errors
      console.log decoder.payloadInline
      console.log decoder.name
      console.log decoder.keywords
      rl.close()