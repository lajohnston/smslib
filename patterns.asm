;====
; Manages patterns (graphic tiles) in the VDP
;
; Provided for example purposes to get you started. For an actual game you
; would want to compress pattern data using an algorithm such as zx7 or aPLib
; and use the appropriate lib to decompress and write to VRAM
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
.define patterns.ELEMENT_SIZE_BYTES 32

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
; Write patterns (tile graphics) into VRAM
;
; @in  dataAddress   the address of the first byte of data
; @in  count         the number of patterns to write (1-based)
; @in  [offset=0]    the number of patterns to skip at the beginning of the data
;====
.macro "patterns.writeSlice" args dataAddr count offset
    .ifndef offset
        utils.outiBlock.writeSlice dataAddr patterns.ELEMENT_SIZE_BYTES count 0
    .else
        utils.outiBlock.writeSlice dataAddr patterns.ELEMENT_SIZE_BYTES count offset
    .endif
.endm

;====
; Write uncompressed patterns into VRAM
;
; @in address   start address of the data
; @in size      data size in bytes. Due to WLA-DX limitations this must be an immediate
;               value, i.e. it can't be calculate from a size calculation like end - start
;               It can be a size label (such as using .incbin "file.bin" fsize size)
;               so long as this label is defined before this macro is called.
;====
.macro "patterns.writeBytes" args address size
    ld hl, address
    utils.outiBlock.write size
.endm

;====
; Set the current pattern index ready to write data into
;
; @in   index    the index number (0-512)
;====
.macro "patterns.setIndex" args index
    utils.vdp.prepWrite (patterns.address + (index * patterns.ELEMENT_SIZE_BYTES))
.endm
