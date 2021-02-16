;====
; Manages patterns (graphic tiles) in the VDP
;
; Provided for example purposes to get you started. For an actual game you
; would want to compress pattern data using an algorithm such as zx7 or aPLib
; and use the appropriate lib to decompress and send to VRAM
;====

;====
; Settings
;
; Define these before including this file if you wish to override the defaults
;====

; Pattern address in VRAM
.ifndef patterns.address
    .define patterns.address $0000
.endif

;====
; Constants
;====
.define patterns.SLOT_SIZE 32

;====
; Dependencies
;====
.ifndef utils.vdp
    .include "utils/vdp.asm"
.endif

;====
; Loads patterns into VRAM
;
; @in  dataAddress   the address of the first byte of data
; @in  size          the size of the data block, in bytes
; @in  patternSlot   the first pattern slot
;====
.macro "patterns.load" args dataAddr slots offset
    .ifndef offset
        utils.vdp.outputArray dataAddr patterns.SLOT_SIZE slots 0
    .else
        utils.vdp.outputArray dataAddr patterns.SLOT_SIZE slots offset
    .endif
.endm

;====
; Set the current pattern slot ready to load data into
; @in   slot    the slot number (0-512)
;====
.macro "patterns.setSlot" args slot
    utils.vdp.prepWrite (patterns.address + (slot * 32))
.endm
