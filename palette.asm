;====
; Color palette
;
; The color palette consists of 32 slots. Each color is a byte
; containing 2-bit RGB colors in the format (--bbggrr).
;
; Background tiles/patterns can use either the first 16 slots, or the
; last 16 slots. Sprites can only use the last 16 slots
;====

;====
; Settings
;====
.ifndef palette.address
    .define palette.address $c000
.endif

;====
; Set a range of colors
;
; @in    fromSlot        the first color slot to set
; @in    numberOfSlots   the number of slots to set
; @in    dataAddress     the address the points to the data to load. Each colour
;                        should be a byte containing an RGB value in the format
;                        --bbggrr
; @clobs af, bc, hl
;====
.macro "palette.set" args fromSlot numberOfSlots dataAddress
    smslib.setVdpWrite palette.address + fromSlot
    ld hl, dataAddress
    ld b, numberOfSlots
    ld c, vdp.DATA_PORT
    otir
.endm
