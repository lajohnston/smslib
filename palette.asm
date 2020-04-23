;====
; Color palette
;
; The color palette consists of 32 slots (0-31). Each color is a byte
; containing 2-bit RGB colors in the format (--bbggrr).
;
; Background tiles/patterns can use either the first 16 slots (0-15), or the
; last 16 slots (16-31). Sprites can only use the last 16 slots (16-31).
;====

.define palette.vramAddress $c000

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
; Loads colors into the palette. Each color should be a byte containing an RGB
; value in the format --bbggrr
;
; @in       dataAddr    the address of the data to load
; @in       endDataAddr the address of the last byte of data
; @in       fromSlot    the first color slot to set (0-31)
;
; @clobs    af, bc, hl
;====
.macro "palette.load" args dataAddr endDataAddr fromSlot
    smslib.prepVdpWrite (palette.vramAddress + fromSlot)
    smslib.copyToVdp dataAddr endDataAddr
.endm
