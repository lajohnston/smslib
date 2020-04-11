;====
; Color palette
;
; The color palette consists of 32 slots (0-31). Each color is a byte
; containing 2-bit RGB colors in the format (--bbggrr).
;
; Background tiles/patterns can use either the first 16 slots (0-15), or the
; last 16 slots (16-31). Sprites can only use the last 16 slots (16-31).
;====

;====
; Settings
;====
.ifndef palette.address
    .define palette.address $c000
.endif

;====
; Loads colors into the palette
;
; @in       fromSlot    the first color slot to set (0-31)
;
; @in       dataAddr    the address of the data to load. Each color
;   should be a byte containing an RGB value in the
;   format --bbggrr
;
; @in       endDataAddr the address of the last byte of data
;
; @clobs    af, bc, hl
;====
.macro "palette.load" args fromSlot dataAddr endDataAddr
    smslib.setVdpWrite palette.address + fromSlot
    ld hl, dataAddr
    ld b, (endDataAddr - dataAddr)
    ld c, vdp.DATA_PORT
    otir
.endm
