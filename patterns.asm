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
.define patterns.MAX_PATTERN_INDEX 511

;====
; Dependencies
;====
.ifndef utils.assert
    .include "utils/assert.asm"
.endif

.ifndef utils.vdp
    .include "utils/vdp.asm"
.endif

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

;====
; Write patterns (tile graphics) into VRAM
;
; @in  dataAddress  the address of the first byte of data
; @in  count        the number of patterns to write (1-based)
; @in  [offset=0]   the number of patterns to skip at the beginning of the data
;====
.macro "patterns.writeSlice" args dataAddress count offset
    utils.assert.label dataAddress, "patterns.asm \.: Invalid dataAddress argument"
    utils.assert.range count, 1, patterns.MAX_PATTERN_INDEX + 1, "patterns.asm \.: Invalid count argument"

    .ifndef offset
        utils.assert.equals NARGS, 2, "patterns.asm \. received the wrong number of arguments"
        utils.outiBlock.writeSlice dataAddress, patterns.ELEMENT_SIZE_BYTES, count, 0
    .else
        utils.assert.equals NARGS, 3, "patterns.asm \. received the wrong number of arguments"
        utils.assert.number offset, "patterns.asm \.: Invalid offset argument"

        utils.outiBlock.writeSlice dataAddress, patterns.ELEMENT_SIZE_BYTES, count, offset
    .endif
.endm

;====
; Write uncompressed patterns into VRAM
;
; @in dataAddress   start address of the data
; @in size          data size in bytes. Due to WLA-DX limitations this must be an
;                   immediate value, i.e. it can't be calculated from a size
;                   calculation like end - start. It can be a fsize label (such as
;                   using .incbin "file.bin" fsize size) so long as this label is
;                   defined before this macro is called.
;====
.macro "patterns.writeBytes" args dataAddress size
    utils.assert.equals NARGS, 2, "patterns.asm \. received the wrong number of arguments"
    utils.assert.label dataAddress, "patterns.asm \.: Invalid dataAddress argument"
    utils.assert.number size, "patterns.asm \.: Invalid size argument"

    ld hl, dataAddress
    utils.outiBlock.write size
.endm

;====
; Set the current pattern index ready to write data into
;
; @in   index    the index number (0-512)
;====
.macro "patterns.setIndex" args index
    utils.assert.equals NARGS, 1, "patterns.asm \. received the wrong number of arguments"
    utils.assert.range index, 0, patterns.MAX_PATTERN_INDEX, "patterns.asm \.: Invalid size argument"

    utils.vdp.prepWrite (patterns.address + (index * patterns.ELEMENT_SIZE_BYTES))
.endm
