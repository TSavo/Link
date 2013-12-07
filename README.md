Link - The Blockchain Filesharing Protocol
====

Link is a protocol designed to allow publishing of data and associated meta-data to the public in such a way that it cannot be censored or destroyed. It works on top of existing blockchain protocols to store it's data by embedding the information in the blockchain itself.

Link works by encoding messages into address, and then spending to those addresses. It's unlikely that a person could know the corasponding private key, so the coins are effectively destroyed. This makes blockchain bloat using the Link protocol prohibitivly expensive, while still allowing the free market to determine a public message's fair value.

Link specifies a specific format for creating transactions which conform to the Link protocol, and therefore can be indexed by clients. This makes Link suitible for inclusion in any blockchain, and allows anyone to implement a client which can parse Link formatted messages out of a blockchain.

Link describes how meta-data can be embedded along with the data, and how to store arbitrary amounts of data by linking transactions together in a sequence.

Link Transaction Format
====

Link transactions contain a specific format, but are really just normal transactions with specially formatted addresses. This allows for normal blockchain operations in a Link transaction.

Input sequences in Link are arbitrary, and are not used to encode data. Therefore any unspent inputs can be used.

A Link spend sequence always starts with the Link Start Sequence op-code: 4c696e6b This must be the first 8 bytes in the spend address, and any spends which come after it are considered continuations of the Link sequence until a no-op op-code is reached (00).

Link transactions encode a series of op-codes into the output addresses which can be parsed by the Link client. Each op code starts with 2 bytes (except for the Link Start Sequence op-code, which is 8 bytes), and may have additional bytes that follow it. In the instance where a variable number of bytes may follow an op-code, the op-code always encodes the number of bytes that follow it. In the case where the number of bytes may be arbitarily large, the number of bytes that encode the content length are also encoded in the op-code.

After the Link Start Sequence op-code, any op-codes may be used in any sequence, including multiple op-codes of the same type where appropiate. In the case of multiple op-codes, any data provided should be concatenated together unless otherwise specified.

For instance, the "payload" op-code is followed by two bytes which specify the size of the length field, followed by that length field which specifies the length of the content, followed by the content itself.

Here's a breakdown of an example "Payload" op-code in hexidecimal:

    01021548656c6c6f20576f726c64

    01 <-- Payload op-code (always 2 bytes)
      02 <-- Number of Content length bytes (always 2 bytes)
        16 <-- Content Length (2 bytes, as specified in the previous field. 22 in decimal)
          48656c6c6f20576f726c64 <-- Actual content (22 bytes, as specified by the previous field)

So to parse this, you would start by reading the first 2 bytes, and determining that this was a payload op-code. The next two bytes specify how many bytes will be used to encode the content length. Since the result is 2, the next two bytes are used to encode the actual content length. Since the result is 22 in binary (16 in hex), 22 more bytes follow that which are the actual content. The bytes that would immideately follow that must be another op-code.

It's important to note that Link spends are always in sequence in the transaction This allow the transaction to do normal spending and change spending before or after including the Link data. By allowing an arbitrary number of op-codes to be encoded, the data per transaction can grow to the maximum transaction size, and by allowing op-codes which link to the next transaction in the sequence, multiple transaction spanning multiple blocks can form a single sequence of data.

The following Link op-codes are supported:

    4c696e6b Link Start Sequence
    01 Payload
    02 Payload disposition
    03 Payload encoding
    04 Payload MD5
    05 Payload SHA-1
    06 Keywords
    FF Next transaction in sequence
