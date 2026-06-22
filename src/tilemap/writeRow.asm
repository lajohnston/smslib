;====
; Load a row (32-tiles) of uncompressed data. Each tile is 2-bytes - the
; first is the patternRef and the second is the tile's attributes.
;
; @in   hl  pointer to the raw data
;====
.macro "tilemap.writeRow"
    ; Output 1 row of data
    utils.outiBlock.write tilemap.ROW_SIZE_BYTES
.endm
