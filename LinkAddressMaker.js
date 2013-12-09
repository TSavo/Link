var crypto = require('crypto');
var BigInteger = require("./jsbn.js");

var alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
function nbi() {
	return new BigInteger(null);
}
function nbv(i) {
	var r = nbi();
	r.fromInt(i);
	return r;
}
BigInteger.valueOf = nbv;
var base = BigInteger.valueOf(58);
BigInteger.fromByteArrayUnsigned = function(ba) {
	if (!ba.length) {
		return ba.valueOf(0);
	} else if (ba[0] & 0x80) {
		// Prepend a zero so the BigInteger class doesn't mistake this
		// for a negative integer.
		return new BigInteger([ 0 ].concat(ba));
	} else {
		return new BigInteger(ba);
	}
};
function hexToBytes(hex) {
	for (var bytes = [], c = 0; c < hex.length; c += 2)
		bytes.push(parseInt(hex.substr(c, 2), 16));
	return bytes;
}

function base58(input) {
	var bi = BigInteger.fromByteArrayUnsigned(input);
	var chars = [];

	while (bi.compareTo(base) >= 0) {
		var mod = bi.mod(base);
		chars.unshift(alphabet[mod.intValue()]);
		bi = bi.subtract(mod).divide(base);
	}
	chars.unshift(alphabet[bi.intValue()]);

	// Convert leading zeros too.
	for (var i = 0; i < input.length; i++) {
		if (input[i] == 0x00) {
			chars.unshift(alphabet[0]);
		} else
			break;
	}
	return chars.join('');
}

function makeAddress(addressBuffer) {
	return base58(hexToBytes(addressBuffer.toString("hex")));
}

function encodeAddress(buf, version) {
	version = version || 0x00;
	var padding = new Buffer(21); // version byte + 20 bytes = 21
	padding.fill(version); // fill with version
	buf.copy(padding, 1, 0); // start a 1 to leave version byte at start
	var sha = crypto.createHash('sha256');
	sha.update(padding); // first round of sha
	var once = sha.digest();
	sha = crypto.createHash('sha256');
	sha.update(once); // second round of sha
	var twice = sha.digest();
	var fin = new Buffer(25); // version byte + 20 bytes + 4 byte checksum =
	// 25
	padding.copy(fin);
	twice.copy(fin, 21); // checksum starts at 21 which is version byte + 20
	// bytes
	return base58(hexToBytes(fin.toString("hex")));
}
function encodeAddresses(buf, version) {
	version = version || 0x00;
	var result = [];
	for (var x = 0; x < buf.length; x = x + 20) { // for every group of 20
		// bytes
		var next = buf.slice(x, x + 20); // get the next 20 bytes
		result.push(encodeAddress(next, version));
	}
	return result;
}

var startSequenceOpCode = "4c696e6b";
var inlinePayloadOpCode = "01";
var nameOpCode = "10";
var keywordsOpCode = "12";
var endSequence = "00";

function encodeHexString(str) {
	return decimalToHex(str.length, 4) + new Buffer(str).toString("hex");
}
function encodePayloadInline(str) {
	return inlinePayloadOpCode + encodeHexString(str);
}
function encodeName(str) {
	return nameOpCode + encodeHexString(str);
}
function encodeKeywords(str) {
	return keywordsOpCode + encodeHexString(str);
}

var LinkSequenceBuilder = function() {
	this.str = startSequenceOpCode, this.toString = function() {
		return this.str + endSequence;
	};
	this.addName = function(name) {
		this.str += encodeName(name);
	};
	this.addKeywords = function(keywords) {
		this.str += encodeKeywords(keywords);
	};
	this.addPayloadInline = function(payload) {
		this.str += encodePayloadInline(payload);
	};
};

function decimalToHex(d, padding) {
	var hex = Number(d).toString(16);
	padding = typeof (padding) === "undefined" || padding === null ? 2
			: padding;
	while (hex.length < padding) {
		hex = "0" + hex;
	}
	return hex;
}

var fs = require('fs');

var readline = require('readline');

var rl = readline.createInterface({
	input : process.stdin,
	output : process.stdout
});

rl.question("What is the magnet link? ", function(magnet) {
	rl.question("What is the name?", function(name) {
		rl.question("Keywords?", function(keywords) {

			var sequence = new LinkSequenceBuilder();
			sequence.addPayloadInline(magnet);
			sequence.addName(name);
			sequence.addKeywords(keywords);
			var buf = new Buffer(sequence.toString(), "hex");
			var addresses = encodeAddresses(buf, 0x00);
			for (x in addresses) {
				console.log(addresses[x]);
			}
			rl.close();
		});
	});
});
