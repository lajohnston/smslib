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

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

;====
; Loads patterns into VRAM
;
; @in  dataAddress   the address of the first byte of data
; @in  count         the number of patterns to load (1-based)
; @in  [offset=0]    the number of patterns to skip at the beginning of the data
;====
.macro "patterns.loadSlice" args dataAddr count offset
    .ifndef offset
        utils.outiBlock.sendSlice dataAddr patterns.SLOT_SIZE count 0
    .else
        utils.outiBlock.sendSlice dataAddr patterns.SLOT_SIZE count offset
    .endif
.endm

;====
; Load uncompressed patterns into VRAM
;
; @in address   start address of the data
; @in size      data size in bytes. Due to WLA-DX limitations this must be an immediate
;               value, i.e. it can't be calculate from a size calculation like end - start
;               It can be a size label (such as using .incbin "file.bin" fsize size)
;               so long as this label is defined before this macro is called.
;====
.macro "patterns.load" args address size
    ld hl, address
    utils.outiBlock.send size
.endm

;====
; Set the current pattern slot ready to load data into
; @in   slot    the slot number (0-512)
;====
.macro "patterns.setSlot" args slot
    utils.vdp.prepWrite (patterns.address + (slot * 32))
.endm
