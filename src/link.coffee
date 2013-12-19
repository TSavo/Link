crypto = require("crypto")
BigInteger = require("jsbn")

alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

nbi = ->
  new BigInteger(null)

nbv = (i) ->
  r = nbi()
  r.fromInt i
  r
  
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
  
decimalToHex = (d, padding) ->
  hex = Number(d).toString(16)
  padding = (if typeof (padding) is "undefined" or padding is null then 2 else padding)
  hex = "0" + hex  while hex.length < padding
  hex
hashBuffer = (algo, buffer) ->
  hash = crypto.createHash algo
  hash.update buffer
  hash.digest()  
  
encodeAddress = (buf, version) ->
  version = version or 0x00
  padding = new Buffer(21) # version byte + 20 bytes = 21
  padding.fill version # fill with version
  buf.copy padding, 1, 0 # start a 1 to leave version byte at start
  twice = hashBuffer "sha256", hashBuffer "sha256", padding
  fin = new Buffer(25) # version byte + 20 bytes + 4 byte checksum = 25
  padding.copy fin
  twice.copy fin, 21 # checksum starts at 21 which is version byte + 20 bytes
  encodeBase58 hexToBytes(fin.toString("hex"))
encodeAddresses = (buf, version) ->
  version = version or 0x00
  result = []
  x = 0 
  while x < buf.length
    next = buf.slice(x, x + 20) # get the next 20 bytes
    result.push encodeAddress(next, version)
    x = x + 20
  result

opCodes =
  startSequenceOpCode: "4c696e6b"
  
  inlinePayloadOpCode: "01"
  attachmentPayloadOpCode: "02"
  mimeTypeOpCode: "03"
  payloadEncodingOpCode: "04"
  payloadMD5OpCode: "05"
  payloadSHA1OpCode: "06"
  payloadSHA256OpCode: "07"

  nameOpCode: "10"
  descriptionOpCode: "11"
  keywordsOpCode: "12"
  uriOpCode: "13"
  filenameOpCode: "14"
  originalCreationDateOpCode: "15"
  lastModifiedDateOpCode: "16"
  licenseOpCode: "17"

  referencesTransactionOpCode: "F1"
  replacesTransactionOpCode: "F2"
  nextTransactionOpCode: "FF"
	
  endSequence: "00"
  
  
class LinkSequenceBuilder
  constructor: (@version) ->
  str: opCodes.startSequenceOpCode
  toString: ->
    @str + opCodes.endSequence
  addName: (name) ->
    @str += @encodeName(name)
  addDescription: (description) ->
    @str += @encodeDescription description
  addURI: (uri) ->
    @str += @encodeURI uri
  addFilename: (filename) ->
    @str += @encodeFilename filename
  addMimeType: (mimeType) ->
    @str += @encodeMimeType mimeType
  addKeywords: (keywords) ->
    @str += @encodeKeywords keywords
  addOriginalCreationDate: (date) ->
    @str += @encodeOriginalCreationDate date
  addLastModifiedDate: (date) ->
    @str += @encodeLastModifiedDate date
  addPayloadInline: (payload) ->
    @str += @encodePayloadInline payload
  addPayloadAttachment: (buf) ->
    @str += @encodePayloadAttachment buf
  addPayloadMD5: (buf) ->
    @str += @encodePayloadMD5Buffer buf
  addPayloadSHA1: (buf) ->
    @str += @encodePayloadSHA1Buffer buf
  addPayloadSHA256: (buf) ->
    @str += @encodePayloadSHA256Buffer buf
  addLicense:(license)->
    @str += @encodeLicense license
  getAddresses: () ->
    encodeAddresses new Buffer(@toString(), "hex"), @version
  encodeBuffer: (buf) ->
    decimalToHex(buf.length, 4) + buf.toString("hex");
  encodeString: (str) ->
    @encodeBuffer(new Buffer(str))
  encodePayloadInline: (str) ->
    opCodes.inlinePayloadOpCode + @encodeString(str)
  encodePayloadAttachment: (buf) ->
    opCodes.attachmentPayloadOpCode + @encodeBuffer(buf)
  encodePayloadEncoding: (str) ->
    opCodes.payloadEncodingOpCode + @encodeString(str)
  encodePayloadMD5Buffer: (buf) ->
    opCodes.payloadMD5OpCode + hashBuffer("md5", buf).toString "hex"
  encodePayloadSHA1Buffer: (buf) ->
    opCodes.payloadSHA1OpCode + hashBuffer("sha1", buf).toString "hex"
  encodePayloadSHA256Buffer: (buf) ->
    opCodes.payloadSHA256OpCode + hashBuffer("sha256", buf).toString "hex"
  encodeName: (str) ->
    opCodes.nameOpCode + @encodeString(str)
  encodeDescription: (str) ->
    opCodes.descriptionOpCode + @encodeString(str)
  encodeURI: (str) ->
    opCodes.uriOpCode + @encodeString(str)
  encodeFilename: (str) ->
    opCodes.filenameOpCode + @encodeString(str)
  encodeKeywords: (str) ->
    opCodes.keywordsOpCode + @encodeString(str)
  encodeMimeType: (str) ->
    opCodes.mimeTypeOpCode + @encodeString(str)
  encodeOriginalCreationDate: (date) ->
    opCodes.originalCreationDateOpCode + decimalToHex(date.getTime(), 12)
  encodeLastModifiedDate: (date) ->
    opCodes.lastModifiedDateOpCode + decimalToHex(date.getTime(), 12)
  encodeLicense: (license) ->
    opcodes.licenseOpCode + @encodeString(str)
    
class LinkSequenceDecoder
  decode: (addresses) ->
    sequence = new Buffer(addresses.length * 20)
    sequence.fill 0x00
    for x of addresses
      new Buffer(bytesToHex(decodeBase58(addresses[x]).slice(1)), "hex").copy sequence, x * 20
    startSequence= new Buffer(4)
    sequence.copy startSequence
    firstFour = startSequence.toString("utf-8")
    throw "First 4 bytes were: " + firstFour unless firstFour is "Link"
    ip = 4
    running = true
    result = {}
    while running 
      nextOp = new Buffer(1)
      sequence.copy nextOp, 0, ip
      op = nextOp.toString("hex")
      ip++
      switch op
        when opCodes.inlinePayloadOpCode
          payload = @decodeString(sequence, ip)
          ip += payload[0]
          result.payloadInline = payload[1]
        when opCodes.nameOpCode
          payload = @decodeString(sequence, ip)
          ip += payload[0]
          result.name = payload[1]
        when opCodes.keywordsOpCode
          payload = @decodeString(sequence, ip)
          ip += payload[0]
          result.keywords = payload[1]
        when opCodes.descriptionOpCode
          payload = @decodeString(sequence, ip)
          ip += payload[0]
          result.description = payload[1]
        when opCodes.uriOpCode
          payload = @decodeString(sequence, ip)
          ip += payload[0]
          result.URI = payload[1]
        when opCodes.filenameOpCode
          payload = @decodeString(sequence, ip)
          ip += payload[0]
          result.filename = payload[1]
        when opCodes.attachmentPayloadOpCode
          payload = @decodeBuffer(sequence, ip)
          ip += payload[0]
          result.payloadAttachment = payload[1].toString("hex")
        when opCodes.payloadMD5OpCode
          payload = @decodeBytes(sequence, ip, 16)
          ip += payload[0]
          result.payloadMD5 = payload[1].toString("hex")
        when opCodes.payloadSHA1OpCode
          payload = @decodeBytes(sequence, ip, 20)
          ip += payload[0]
          result.payloadSHA1 = payload[1].toString("hex")
        when opCodes.payloadSHA256OpCode
          payload = @decodeBytes(sequence, ip, 32)
          ip += payload[0]
          result.payloadSHA256 = payload[1].toString("hex")
        when opCodes.originalCreationDateOpCode
          result.originalCreationDate = @decodeDate(sequence, ip)
          ip += 6
        when opCodes.lastModifiedDateOpCode
          result.lastModifiedDate = @decodeDate(sequence, ip)
          ip += 6;
        when opCodes.licenseOpCode
          payload = @decodeString(sequence, ip)
          ip += payload[0]
          result.license = payload[1]
        when opCodes.endSequence
          running = false
    result
  verify: (result)->
    errors = []
    p = result.payloadAttachment or result.payloadInline;
    if not p? then return
    if result.payloadMD5?
      h = hashBuffer "md5", p
      if(h.toString("hex") != result.payloadMD5)
        errors.push("Expected MD5 was #{result.payloadMD5} but the payload MD5 is #{h}")
    if result.payloadSHA1?
      h = hashBuffer "sha1", p
      if(h.toString("hex") != result.payloadSHA1)
        errors.push("Expected SHA-1 was #{result.payloadSHA1} but the payload SHA-1 is #{h}")
    if result.payloadSHA256?
      h = hashBuffer "sha256", p
      if(h.toString("hex") != result.payloadSHA256)
        errors.push("Expected SHA-256 was #{result.payloadSHA256} but the payload SHA-256 is #{h}")
    errors
  decodeSize: (buffer, ip) ->
    parseInt @decodeBytes(buffer, ip, 2)[1].toString("hex"), 16
  decodeString: (buffer, ip) ->
    size = @decodeSize(buffer, ip)
    [size + 2, @decodeBytes(buffer, ip + 2, size)[1].toString("utf-8")]
  decodeBuffer: (buffer, ip) ->
    size = decodeSize(buffer, ip)
    [size + 2, @decodeBytes(buffer, ip+2, size)[1]]
  decodeBytes: (buffer, ip, length) ->
    p = new Buffer(length)
    buffer.copy p, 0, ip
    [length, p]
  decodeDate: (buffer, ip) ->
    buf = new Buffer 6
    buffer.copy buf, 0, ip
    d = new Date parseInt buf.toString("hex"), 16
      
if exports? 
  exports.LinkSequenceBuilder = module.exports.LinkSequenceBuilder = LinkSequenceBuilder;
  exports.LinkSequenceEncoder = module.exports.LinkSequenceDecoder = LinkSequenceDecoder;
  exports.opCodes = module.exports.opCodes = opCodes;
  exports.decodeBase58 = decodeBase58
  exports.encodeBase58 = encodeBase58
  exports.bytesToHex = bytesToHex
  exports.hashBuffer = hashBuffer

  