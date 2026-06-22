;====
; Write tile data from an uncompressed map. Each tile is 2-bytes - the first is
; the tileRef and the second is the tile's attributes.
;
; @in   d   number of rows to write
; @in   e   the amount to increment the pointer by each row i.e. the number of
;           columns in the full map * 2 (as each tile is 2-bytes)
; @in   hl  pointer to the first tile to write
;====
.macro "tilemap.writeRows"
    utils.clobbers "af", "bc", "de"
        call tilemap._writeRows
    utils.clobbers.end
.endm

;====
; Private (see macro)
;====
.section "tilemap._writeRows"
    _nextRow:
        ld a, e                 ; write row width into A
        utils.math.addHLA       ; add 1 row to full tilemap pointer

    tilemap._writeRows:
        push hl                 ; preserve HL
            tilemap.writeRow    ; write a row of data
        pop hl                  ; restore HL

        dec d
        jp nz, _nextRow
        ret
.ends
