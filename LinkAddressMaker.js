var Bitcoin = new Object();

var alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

var BigInteger = require("./jsbn.js");
function nbi() { return new BigInteger(null); }
function nbv(i) { var r = nbi(); r.fromInt(i); return r; }
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

var versionNumber = 0;

var crypto = require('crypto');
var fs = require('fs');

var readline = require('readline');

var rl = readline.createInterface({
	input : process.stdin,
	output : process.stdout
});

var startSequenceOpCode = "4c696e6b";
var inlinePayloadOpCode = "01";
var nameOpCode = "10";
var keywordsOpCode = "12";
var endSequence = "00";

function decimalToHex(d, padding) {
	var hex = Number(d).toString(16);
	padding = typeof (padding) === "undefined" || padding === null ? padding = 2
			: padding;

	while (hex.length < padding) {
		hex = "0" + hex;
	}

	return hex;
}
rl.question("What is the magnet link? ", function(magnet) {
	rl.question("What is the name?", function(name) {
		rl.question("Keywords?", function(keywords) {
			var str = startSequenceOpCode;
			str += inlinePayloadOpCode + decimalToHex(magnet.length, 4)
					+ new Buffer(magnet).toString("hex");
			str += nameOpCode + decimalToHex(name.length, 4)
					+ new Buffer(name).toString("hex");
			str += keywordsOpCode + decimalToHex(keywords.length, 4)
					+ new Buffer(keywords).toString("hex");
			str += endSequence;
			var buf = new Buffer(str, "hex");
			for (var x = 0; x < buf.length; x = x + 20) {
				var addy = buf.slice(x, x + 20);
				var padding = new Buffer(21);
				padding.fill(0x00);
				addy.copy(padding, 1, 0);
				var sha = crypto.createHash('sha256');
				sha.update(padding);
				var once = sha.digest();
				sha = crypto.createHash('sha256');
				sha.update(once);
				var twice = sha.digest();
				var fin = new Buffer(25);
				fin.fill(0x00);
				padding.copy(fin);
				twice.copy(fin, 21, 0);
				console.log(base58(hexToBytes(fin.toString("hex"))));
			}
			rl.close();
		});
	});
});
