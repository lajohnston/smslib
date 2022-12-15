;====
; Generates a map of metatile references. Each ref is a byte and refers to one
; of the metatile definitions (0-255).
;
; Here we programmatically generate the map but a real game may have a designed
; map that's compressed on the ROM.
;====

; The max height for the map will be the MAX_MAP_BYTES value divided by the width
.define MAP_HEIGHT_METATILES scroll.metatiles.MAX_MAP_BYTES / MAP_WIDTH_METATILES

.repeat MAP_HEIGHT_METATILES index row
    .repeat MAP_WIDTH_METATILES index col
        .if row == 0 || col == 0 || row == MAP_HEIGHT_METATILES - 1 || col == MAP_WIDTH_METATILES - 1
            ; Border around the edges
            .db 5   ; metatile #5
        .else
            ; Diagonal stripes in middle
            .db ((row + col) # 4)
        .endif
    .endr
.endr
