;====
; Programmatically creates some metatiles definitions according to the size,
; to demonstrate the flexible scroll.metatiles.ROWS_PER_METATILE and
; scroll.metatiles.COLS_PER_METATILE values you can set. Set these in the
; metatile scrolling example before including the scroll/metatiles.asm file.
;
; Each metatile definition is square or rectangle with its own color.
;====

; The number of metatiles definitions/colors
.define colors = 6

.if scroll.metatiles.ROWS_PER_METATILE == 2 && scroll.metatiles.COLS_PER_METATILE == 2
    ; 2x2 metatiles just require four corners
    .repeat colors index color
        .redefine cornerPattern color * 4

        tilemap.tile cornerPattern
        tilemap.tile cornerPattern tilemap.FLIP_X
        tilemap.tile cornerPattern tilemap.FLIP_Y
        tilemap.tile cornerPattern tilemap.FLIP_XY
    .endr
.else
    ; Larger metatiles require corners, side, and middle
    .repeat colors index color
        ; Pattern numbers that define the corners, sides and middle
        .redefine basePattern      color * 4            ; the first pattern for this color
        .redefine cornerPattern    basePattern          ; corner outline
        .redefine sideEdgePattern  basePattern + 1      ; side outline (vertical line)
        .redefine topEdgePattern   basePattern + 2      ; top outline (horizontal line)
        .redefine middlePattern    basePattern + 3      ; plain tile without an outline

        ;===
        ; Top row
        ;===
        tilemap.tile cornerPattern                          ; top left corner

        .repeat scroll.metatiles.COLS_PER_METATILE - 2
            tilemap.tile topEdgePattern                     ; top edge
        .endr

        tilemap.tile cornerPattern tilemap.FLIP_X           ; top right corner

        ;===
        ; Middle rows
        ;===
        .repeat scroll.metatiles.ROWS_PER_METATILE - 2
            tilemap.tile sideEdgePattern                    ; left edge

            .repeat scroll.metatiles.COLS_PER_METATILE - 2
                tilemap.tile middlePattern                  ; middle
            .endr

            tilemap.tile sideEdgePattern tilemap.FLIP_X     ; right edge
        .endr

        ;===
        ; Last row
        ;===
        tilemap.tile cornerPattern tilemap.FLIP_Y           ; bottom left corner

        .repeat scroll.metatiles.COLS_PER_METATILE - 2
            tilemap.tile topEdgePattern tilemap.FLIP_Y      ; bottom middle edge
        .endr

        tilemap.tile cornerPattern tilemap.FLIP_XY          ; bottom right corner
    .endr
.endif
