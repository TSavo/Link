# Modules
Modules allow the Link Filesharing Protocol to be extended to other uses. Each module is assigned a unique identifier to distinguish it from other modules. Each module also has a collection of opcodes set aside for that identifier. The opcodes specify a slot index and a function number.

# Slots
There are 16 slots allowing for 16 modules to be active at the same time. Each slot has 16 function numbers for descriptions, strings, or other data. Except in the reserved and required slots, function F of each slot contains the unique identifier for that module. This allows modules to use more than one slot so that it can have more than the 16 functions of a single slot.

# Reserved and Required Slots
The Link protocol reserves two slots at indices 0 and F. Opcodes 00 through 0F are in slot 0, which is reserved for the core module. Opcodes F0 through FF are in slot F, which is reserved for the sequencing module. The Link protocol also requires the meta-data module to be assigned at slot 1, providing opcodes 10 through 1F.

# Open Slots and Functions
Before a module can be used, an open slot and functions must be associated with it using a unique identifier. The identifier is made of a signature and a function offset. The signature associates a module with a slot. The function offset associates a selection of module functions with that slot so that modules with large function libraries can be used.

# Opcode Examples
## Reserved or Required Slot Opcodes:
 * Specify a reserved opcode, such as 00 - 0F or F0 - FF.
 * Or instead specify a required opcode, such as 10 - 1F.
 * Follow the opcode with data for the opcode.
 * Opcodes and data may be used at any time.

## Open Slot Opcodes
 * Specify the loading opcode, made of slot number and function F, such as 2F, 3F, 4F, etc.
 * Specify the loading opcode identifier data, made of the signature and the function offset, such as MYMODULE1337:00.
 * Further opcodes, except those referencing function F, will refer to functions from the collection at offset 00 from the module MYMODULE1337.
 * To switch modules in a slot repeat the first two steps.

## Collections of Functions
 * Each module has a unlimited number of functions.
 * Each module has up to 256 function offsets.
 * Each offset defines a list of up to 15 function numbers that may be used corresponding to the opcodes.
 * Each function may appear in more than one offset.

## Signatures
 * Signatures are digests of strings associated with each module.
 * Signatures must be unique for each module.
 * Signatures can be used in more than one slot.
 * Switched out modules are put into hibernation until resumed.
