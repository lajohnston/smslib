;====
; Color palette
;
; The color palette consists of 32 color entries (0-31). Each color is a byte
; containing 2-bit RGB colors in the format (--bbggrr).
;
; Background tiles/patterns can use either the first 16 indices (0-15), or the
; last 16 (16-31). Sprites can only use the last 16 (16-31).
;====

;====
; Dependencies
;====
.ifndef utils.assert
    .include "utils/assert.asm"
.endif

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

.ifndef utils.vdp
    .include "utils/vdp.asm"
.endif

;====
; Constants
;====
.define palette.ELEMENT_SIZE_BYTES 1
.define palette.SPRITE_PALETTE 16
.define palette.VRAM_ADDR $c000

;====
; Procedures
;====

;====
; Defines a byte with an approximate RGB value. Each color component is rounded
; to the nearest 85 (0, 85, 170, 255)
;====
.macro "palette.rgb" args red green blue
    utils.assert.equals NARGS, 3, "palette.asm \. received the wrong number of arguments"
    utils.assert.number red, "palette.asm \.: Invalid red argument"
    utils.assert.number green, "palette.asm \.: Invalid green argument"
    utils.assert.number blue, "palette.asm \.: Invalid blue argument"

    ; Round to nearest 85 then AND with $ff to calculate floor
    .define \.\@red = (red + 42.5) / 85 & $ff
    .define \.\@green = (green + 42.5) / 85 & $ff
    .define \.\@blue = (blue + 42.5) / 85 & $ff

    ; Convert to --bbggrr
    .db (\.\@blue * 16) + (\.\@green * 4) + \.\@red
.endm

;====
; Write an approximate RGB value into the current palette index. Each value
; will be rounded to the nearest of: 0, 85, 170, 255
;
; @in   red     red value
; @in   green   green value
; @in   blue    blue value
;====
.macro "palette.writeRgb" args red, green, blue
    utils.assert.equals NARGS, 3, "palette.asm \. received the wrong number of arguments"
    utils.assert.number red, "palette.asm \.: Invalid red argument"
    utils.assert.number green, "palette.asm \.: Invalid green argument"
    utils.assert.number blue, "palette.asm \.: Invalid blue argument"

    ; Round to nearest 85 then AND with $ff to calculate floor
    .define \.\@red = (red + 42.5) / 85 & $ff
    .define \.\@green = (green + 42.5) / 85 & $ff
    .define \.\@blue = (blue + 42.5) / 85 & $ff

    ; Convert to --bbggrr
    ld a, (\.\@blue * 16) + (\.\@green * 4) + \.\@red
    out (c), a  ;   write color
.endm

;====
; Write raw color data into Color RAM
;
; @in address   start address of the palette data
; @in size      data size in bytes. Due to WLA-DX limitations this must be an immediate
;               value, i.e. it can't be calculate from a size calculation like end - start
;               It can be a size label (such as using .incbin "file.bin" fsize size)
;               so long as this label is defined before this macro is called.
;====
.macro "palette.writeBytes" args address size
    utils.assert.equals NARGS, 2, "palette.asm \. received the wrong number of arguments"
    utils.assert.label address, "palette.asm \.: Invalid address argument"
    utils.assert.number size, "palette.asm \.: Invalid size argument"

    ld hl, address
    utils.outiBlock.write size
.endm

;====
; Writes colors into color RAM. Each color should be a byte containing an RGB
; value in the format --bbggrr
;
; @in       dataAddr    the address of the data to write
; @in       count       the number of colors to write
; @in       [offset=0]  how many colors to skip from the start of the data
;====
.macro "palette.writeSlice" args dataAddr count offset
    utils.assert.label dataAddr, "palette.asm \.: Invalid label argument"
    utils.assert.number count, "palette.asm \.: Invalid count argument"

    .ifdef offset
        utils.assert.equals NARGS, 3, "palette.asm \. received the wrong number of arguments"
        utils.assert.number offset, "palette.asm \.: Expected count to be a numeric value"
        utils.outiBlock.writeSlice dataAddr, palette.ELEMENT_SIZE_BYTES, count, offset
    .else
        utils.assert.equals NARGS, 2, "palette.asm \. received the wrong number of arguments"
        utils.outiBlock.writeSlice dataAddr, palette.ELEMENT_SIZE_BYTES, count, 0
    .endif
.endm

;====
; Set the current palette index (0-31) ready to write data into
;
; @in   index   the palette index (0-31)
;====
.macro "palette.setIndex" args index
    utils.assert.equals NARGS, 1, "palette.asm \. received the wrong number of arguments"
    utils.assert.range index, 0, 31, "palette.asm \.: Invalid index argument"

    utils.vdp.prepWrite (palette.VRAM_ADDR + index)
.endm
