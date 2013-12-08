Link - The Blockchain Filesharing Protocol
====

Link is a protocol designed to allow publishing of data and associated meta-data to the public in such a way that it cannot be censored or destroyed. It works on top of existing blockchain protocols to store it's data by embedding the information in the blockchain itself.

Link works by encoding messages into address, and then spending to those addresses. It's unlikely that a person could know the corasponding private key, so the coins are effectively destroyed. This makes blockchain bloat using the Link protocol prohibitivly expensive, while still allowing the free market to determine a public message's fair value.

Link specifies a specific format for creating transactions which conform to the Link protocol, and therefore can be indexed by clients. This makes Link suitible for inclusion in any blockchain, and allows anyone to implement a client which can parse Link formatted messages out of a blockchain.

Link describes how meta-data can be embedded along with the data, and how to store arbitrary amounts of data by linking transactions together in a sequence.

Link is designed as a protocol that rides on top of existing blockchain protocols, and it purposefully does NOT specify the rules for usage, only the suggested message types, called op-codes. It's entirely up to the message creator, and the consuming client for how to intrepret the information present. It's implied that any message type can be repeated multiple times, and in fact for multi-transaction messages, this is a requirement of the parser.

##Link Transaction Format

Link transactions contain a specific format, but are really just normal transactions with specially formatted addresses. This allows for normal blockchain operations in a Link transaction.

Input sequences in Link are arbitrary, and are not used to encode data. Therefore any unspent inputs can be used.

A Link spend sequence always starts with the Link Start Sequence op-code: "4c 69 6e 6b"

This must be the first 4 bytes in the spend address, and any spends which come after it are considered continuations of the Link sequence until a no-op op-code is reached (00).

Link transactions encode a series of op-codes into the output addresses which can be parsed by the Link client. Each op code starts with 1 byte, and may have additional bytes that follow it. In the instance where a variable number of bytes may follow an op-code, the op-code always encodes the number of bytes that follow it.

After the Link Start Sequence op-code, any op-codes may be used in any sequence, including multiple op-codes of the same type where appropiate. In the case of multiple op-codes, any data provided should be concatenated together unless otherwise specified. Since all size fields are 1 bytes, the maximum size for a operand will be 65,535, so it's necessary to repeat a "payload" op code to encode more than 65,535 bytes in a sequence. 

For instance, the "payload" op-code is followed by two bytes which specify the length of the content, followed by the content itself.

Here's a breakdown of an example "Payload" op-code in hexidecimal:

    01 0B 48 65 6c 6c 6f 20 57 6f 72 6c 64
    ^^ Payload op-code (1 bytes)
       ^^ Content Length (1 byte. 11 in decimal)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Actual content (11 bytes, as specified by the previous field)

So to parse this, you would start by reading the first 2 bytes, and determining that this was a payload op-code. The next two bytes specify how many bytes will be used to encode the content length. Since the result is 2, the next two bytes are used to encode the actual content length. Since the result is 22 in binary (16 in hex), 22 more bytes follow that which are the actual content. The bytes that would immideately follow that must be another op-code.

It's important to note that Link spends are always in sequence in the transaction This allow the transaction to do normal spending and change spending before or after including the Link data. By allowing an arbitrary number of op-codes to be encoded, the data per transaction can grow to the maximum transaction size, and by allowing op-codes which link to the next transaction in the sequence, multiple transaction spanning multiple blocks can form a single sequence of data.

The following Link op-codes are supported:

| Op Code (in hex) | Operation |
| -----------:|:------------------------------- |
| 4c696e6b | Link Start Sequence |
| No-op/End| 00 |
| 01 | Payload (inline) |
| 02 |Payload (attachment) |
| 03 |Payload mime-type |
| 04 |Payload encoding |
| 05 |Payload MD5 |
| 06 |Payload SHA-1 |
| 07 |Payload SHA-256 |
| 10 |Name |
| 11 |Description |
| 12 |Keywords |
| 13 |URI |
| 14 |File name |
| 15 |Original Creation Date (unix timestamp) |
| 16 |Last Modified Date (unix timestamp) |
| 1F |Arbitrary user-defined meta-data |
| 2X |Reserved for Flux |
| F1 |References transaction |
| F2 |Replaces transaction |
| FF |Next transaction in sequence (required for multi-transaction sequences) |

##Payload Op-Codes (0)

###Payload (inline disposition)

Payload is intended to be extracted from the data in accordance with the encoding and disposition. Multiple payload blocks are allowed, and the data should be concatenated together in the sequence it appears in the stream. This allows payload data to span outputs, transactions, and even blocks.

Inline payloads are designed to be handled by the client by delegating to a protocol handler.

* Op-code: 01
* Operands: 3
 1. 2 bytes encoding payload size X
 2. X bytes as specified by operand 1, encoding the payload

###Payload (attachment disposition)

This is the same as the inline payload, but instead of being executed as a protocol handler, the stream of bytes are expected to be saved to disk.

* Op-code: 02
* Operands: 2
 1. 2 bytes encoding operand 2 size X
 2. X bytes as specified by operand 1, encoding the payload
 
###Payload mime-type

This is the mime-type of the payload. The default encoding is "application/octet-stream".

* Op-code: 03
* Operands: 2
 1. 1 byte encoding operand 2 size X
 2. X bytes as specified by operand 1, encoding the payload mime-type

###Payload encoding

This is the type of encoding for the payload itself. The default encoding is "UTF-8", but others may be specified, like "base64".

* Op-code: 04
* Operands: 2
 1. 1 byte encoding the payload encoding string size X
 2. X bytes as specified by operand 1, encoding the payload encoding

###Payload MD5

The MD5 hash of the payload.

* Op-code: 05
* Operands: 1
 1. 16 bytes, the MD5 hash of the payload.

###Payload SHA-1

The SHA-1 hash of the payload.

* Op-code: 06
* Operands: 1
 1. 20 bytes, the SHA-1 hash of the payload

###Payload SHA-256

The SHA-256 hash of the payload.

* Op-code: 07
* Operands: 1
 1. 32 bytes, the SHA-256 hash of the payload

##Meta-data op-codes (1)

###Name

The name of the sequence.

* Op-code: 10
* Operands: 2
 1. 2 bytes, the size of the file name X
 2. X bytes as specified by operand 1, the name of the sequence

###Description

The description of the sequence.

* Op-code: 11
* Operands: 2
 1. 2 bytes, the size of the description X
 2. X bytes as specified by operand 1, the description of the sequence

###Keywords

The keywords to index quick searches by. Expected to be a comma seperated list.

* Op-code: 12
* Operands: 2
 1. 2 bytes, the size of the keywords X
 2. X bytes as specified by operand 1, the keywords

###URI

The URI that is associated with this sequence.

* Op-code: 13
* Operands: 2
 1. 2 bytes, the size of the URI X
 2. X bytes as specified by operand 1, the URI associated with this sequence

###File Name

The file name of the attachment payload. 

* Op-code: 14
* Operands: 2
 1. 2 bytes, the size of the file name X
 2. X bytes as specified by operand 1, the URI associated with this sequence.
  
###Original Creation Date (unix timestamp)

The Unix timestamp of the original creation date.

* Op-code: 15
* Operands: 1
 1. 4 bytes, the unix timestamp of the original creation date

###Last Modified Date (unix timestamp)

* Op-code: 16
* Operands: 1
 1. 4 bytes, the unix timestamp of the last modified date

###Arbitrailly defined Meta-data

A "free form field" for unformatted meta-data.

* Op-code: 1F
* Operands: 2
 1. 2 bytes, the size of the meta-data X
 2. X bytes as defined by operand 1, the meta-data

##Sequencing op-codes (F)

Sequencing allows a Link sequence to span multiple transactions.

###References transaction

This sequence is in reply to or reference another transaction.

* Op-code: F0
* Operands: 1
 1. 32 bytes, the id of the tx being references

##Replaces transaction

This sequence superceeds another transaction.

* Op-code: F1
* Operands: 1
 1. 32 bytes, the id of the tx being references

##Next transaction in sequence

This allows for multi-transaction sequences. By referencing another transaction which also has a Link sequence embedded in it, both transactions are considered included in the sequence.

* Op-code: FF
* Operands: 1
 1. 32 bytes, the id of the tx that continues this sequence

##Example sequences

###Basic file encoding

Here we're encoding a file with the following properties:

Attachment Payload: "Hello World" (48 65 6c 6c 6f 20 57 6f 72 6c 64, 11 bytes)

Filename: "greeting.txt" (67 72 65 65 74 69 6e 67 2e 74 78 74, 10 bytes)

Created date: 12/08/2013 @ 7:29am (1386487795 unix timestamp, 52 A4 1F F3, 4 bytes)

Last Modified date: 12/08/2013 @ 7:32am (1386487972 unix timestamp, 52 A4 20 A4, 4 bytes)


The raw stream to encode this is:

```

4c 69 6e 6b 02 0B 48 65 6c 6c 6f 20 57 6f 72 6c 64 14 0A 67 72 65 65 74 69 6e 67 2e 74 78 74 15 52 A4 1F F3 16 52 A4 20 A4 00

```

Broken out:

```

4c 69 6e 6b 02 0B 48 65 6c 6c 6f 20 57 6f 72 6c 64
^^^^^^^^^^^ Link Sequence op-code
            ^^ Payload op-code (1 bytes)
               ^^ Content length (1 byte. 11 in decimal)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Actual content (11 bytes, as specified by the previous field)

14 0A 67 72 65 65 74 69 6e 67 2e 74 78 74
^^ Filename op-code (1 byte)
   ^^ Content length (1 byte)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Actual content (10 bytes)
      
15 52 A4 1F F3 16 52 A4 20 A4 00
^^ Original creation date op-code (1 byte)
   ^^^^^^^^^^^ Created on unix timestamp (4 bytes)
               ^^ Last modified date op-code (1 byte)
                  ^^^^^^^^^^^ Last modified unix timestamp (4 bytes)
                              ^^ End sequence op-code
   

```



