Link - The Blockchain Filesharing Protocol
====

Link is a protocol designed to allow publishing of data and associated meta-data to the public in such a way that it cannot be censored or destroyed. It works on top of existing blockchain protocols to store it's data by embedding the information in the blockchain itself.

Link works by encoding messages into address, and then spending to those addresses. It's unlikely that a person could know the corasponding private key, so the coins are effectively destroyed. This makes blockchain bloat using the Link protocol prohibitivly expensive, while still allowing the free market to determine a public message's fair value.

Link specifies a specific format for creating transactions which conform to the Link protocol, and therefore can be indexed by clients. This makes Link suitible for inclusion in any blockchain, and allows anyone to implement a client which can parse Link formatted messages out of a blockchain.

Link describes how meta-data can be embedded along with the data, and how to store arbitrary amounts of data by linking transactions together in a sequence.

Link Transaction Format
====

Link transactions contain a specific format, but are really just normal transactions with specially formatted addresses. This allows for normal blockchain operations in a Link transaction.

Input sequences in Link are arbitrary, and are not used to encode data. Therefore any unspend inputs can be used. All Link transaction contains the following outputs:

0 or more normal spends, such as change spends.
1 or more of the following sequences:
  1 meta-data spends.
  Between 0 and 9 data spends.

It's important to note that the data spends always come immideately after the Meta-data spend in the sequence. This allow the transaction to do normal spending and change spending before or after including the Link data. By allowing multiple meta-data/data descriptions in a transaction, the data per transaction can grow to the maximum transaction size, and by allowing the meta-data to link to the next transaction in the sequence, multiple transaction spanning multiple blocks can form a single sequence of data.

The first transaction in a sequence must always contain at least one Link output, which has the following address format:

    42AABBCCDDEEFFGGHHII
    
    42 <-- Link Meta-Data
      AA <-- First Data Segment Description
        BB <-- Second Data Segment Description
          CC <-- Third Data Segment Description
            DD <-- Fourth Data Segment Description
              EE <-- Fifth Data Segment Description
                FF <-- Sixth Data Segment Description
                  GG <-- Seventh Data Segment Description
                    HH <-- Eighth Data Segment Description
                      II <-- Ninth Data Segment Description

Each data segment is the next spend in the transaction, and is essentially raw data, but by specifying it's description in the initial meta-data spend, this allows for the full 20 bytes to be used for the data itself while specifying what to do with the data.

The following table shows which codes represent which data type:

    00 - No data (the spend isn't present, or should be ignored)
    01 - Main Data (multiple will be concatenated together)
    02 - Keywords (a null seperated list of UTF-8 encoded keywords, multiple are allowed)
    03 - Next TXid (the first-bits of the next TX in the sequence, only one is allowed)

