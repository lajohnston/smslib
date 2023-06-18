# utils.ram

General Z80 routines for manipulating RAM values.

## Importing

If you're including the whole smslib.asm library then this will probably already have been imported, otherwise you can safely import it as follows:

```
.ifndef utils.ram
    .include "utils/ram.asm"
.endif
```

## utils.ram.fill

Fills a portion of RAM with a value.

```
; Fill 20-bytes of RAM with the value of 0, starting from someAddress
utils.ram.fill 20 someAddress 0

; Fill 20-bytes of RAM with the value stored in A, starting from someAddress
ld a, 123
utils.ram.fill 20 someAddress

; Fill 20-bytes of RAM with the value stored in A, starting from HL
ld hl, someAddress
ld a, 123
utils.ram.fill 20
```
