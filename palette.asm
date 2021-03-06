;====
; Color palette
;
; The color palette consists of 32 slots (0-31). Each color is a byte
; containing 2-bit RGB colors in the format (--bbggrr).
;
; Background tiles/patterns can use either the first 16 slots (0-15), or the
; last 16 slots (16-31). Sprites can only use the last 16 slots (16-31).
;====

.define palette.VRAM_ADDR $c000
.define palette.SLOT_SIZE 1
.define palette.SPRITE_PALETTE 16

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
; Procedures
;====

;====
; Defines a byte with an approximate RGB value. Each color component is rounded
; to the nearest 85 (0, 85, 170, 255)
;====
.macro "palette.rgb" args red green blue
    ; Round to nearest 85 then AND with $ff to calculate floor
    .define _palette.redAdj\@ = (red + 42.5) / 85 & $ff
    .define _palette.greenAdj\@ = (green + 42.5) / 85 & $ff
    .define _palette.blueAdj\@ = (blue + 42.5) / 85 & $ff

    ; Convert to --bbggrr
    .db _palette.redAdj\@ + (_palette.greenAdj\@ * 4) + (_palette.blueAdj\@ * 16)
.endm

;====
; Load colors into Color RAM
;
; @in address   start address of the palette data
; @in size      data size in bytes. Due to WLA-DX limitations this must be an immediate
;               value, i.e. it can't be calculate from a size calculation like end - start
;               It can be a size label (such as using .incbin "file.bin" fsize size)
;               so long as this label is defined before this macro is called.
;====
.macro "palette.load" args address size
    ld hl, address
    utils.outiBlock.send size
.endm

;====
; Loads colors into the palette. Each color should be a byte containing an RGB
; value in the format --bbggrr
;
; @in       dataAddr    the address of the data to load
; @in       count       the number of colors to load
; @in       [offset=0]  how many colors to skip from the start of the data
;====
.macro "palette.loadSlice" args dataAddr count offset
    .ifndef offset
        utils.outiBlock.sendSlice dataAddr palette.SLOT_SIZE count 0
    .else
        utils.outiBlock.sendSlice dataAddr palette.SLOT_SIZE count offset
    .endif
.endm

;====
; Set the current palette slot (0-31) ready to load data into
;
; @in slot  the palette slot (0-31)
;====
.macro "palette.setSlot" args slot
    utils.vdp.prepWrite (palette.VRAM_ADDR + slot)
.endm
