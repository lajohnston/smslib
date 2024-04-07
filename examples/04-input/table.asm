;====
; A table that will indicate which button conditions are true for the
; current frame
;====

; The starting row the render the table from
.define TABLE_ROW_OFFSET = 5

; The indicator tile columns for each condition (Pressed, Current, Held)
.define INDICATOR_COLUMN_START = 9
.define PRESSED_INDICATOR_COLUMN = INDICATOR_COLUMN_START + 1
.define CURRENT_INDICATOR_COLUMN = PRESSED_INDICATOR_COLUMN + 6
.define HELD_INDICATOR_COLUMN = CURRENT_INDICATOR_COLUMN + 6
.define RELEASED_INDICATOR_COLUMN = HELD_INDICATOR_COLUMN + 6

; The row number for each button
.define TABLE_BODY_ROW = TABLE_ROW_OFFSET + 4
.define UP_ROW = TABLE_BODY_ROW
.define DOWN_ROW = TABLE_BODY_ROW + 1
.define LEFT_ROW = TABLE_BODY_ROW + 2
.define RIGHT_ROW = TABLE_BODY_ROW + 3
.define BUTTON_1_ROW = TABLE_BODY_ROW + 5
.define BUTTON_2_ROW = TABLE_BODY_ROW + 6
.define COMBO_ROW = TABLE_BODY_ROW + 8

; Map ASCII data to byte values so we can use .asc later (see wla-dx docs)
.asciitable
    map " " to "~" = 0
.enda

.section "assets" free
    table.fontPalette:
        palette.rgb 0, 0, 0
        palette.rgb 170, 85, 170

    table.fontPatterns:
        .incbin "../assets/font.bin" fsize table.fontPatternsSize

    ; Table template
    table.template:
        .asc "       Pressed                  "
        .asc "             Current            "
        .asc "                    Held        "
        .asc "                        Released"
        .asc "Up       ( )   ( )   ( )   ( )  "
        .asc "Down     ( )   ( )   ( )   ( )  "
        .asc "Left     ( )   ( )   ( )   ( )  "
        .asc "Right    ( )   ( )   ( )   ( )  "
        .asc "                                "
        .asc "Button 1 ( )   ( )   ( )   ( )  "
        .asc "Button 2 ( )   ( )   ( )   ( )  "
        .asc "                                "
        .asc "Up and 1 ( )   ( )   ( )   ( )  "
        .db $ff ; terminator

    table.blankRow:
        .asc "( )   ( )   ( )   ( )"
        .db $ff ; terminator

    ; We'll add an asterisk in between the brackets in the template string,
    ; indicating which condition has been met
    table.asciiAsterisk:
        .asc '*'
.ends

;====
; Draws the blank table with none of the indicators populated
;====
.section "table.draw" free
    table.draw:
        palette.setIndex 0
        palette.writeBytes table.fontPalette 2

        patterns.setIndex 0
        patterns.writeBytes table.fontPatterns, table.fontPatternsSize

        tilemap.setColRow 0, TABLE_ROW_OFFSET
        tilemap.writeBytesUntil $ff, table.template
        ret
.ends

;====
; Resets the indicators in the table
;====
.section "table.reset" free
    table.reset:
        tilemap.setColRow INDICATOR_COLUMN_START, UP_ROW
        tilemap.writeBytesUntil $ff table.blankRow

        tilemap.setColRow INDICATOR_COLUMN_START, DOWN_ROW
        tilemap.writeBytesUntil $ff table.blankRow

        tilemap.setColRow INDICATOR_COLUMN_START, LEFT_ROW
        tilemap.writeBytesUntil $ff table.blankRow

        tilemap.setColRow INDICATOR_COLUMN_START, RIGHT_ROW
        tilemap.writeBytesUntil $ff table.blankRow

        tilemap.setColRow INDICATOR_COLUMN_START, BUTTON_1_ROW
        tilemap.writeBytesUntil $ff table.blankRow

        tilemap.setColRow INDICATOR_COLUMN_START, BUTTON_2_ROW
        tilemap.writeBytesUntil $ff table.blankRow

        tilemap.setColRow INDICATOR_COLUMN_START, COMBO_ROW
        tilemap.writeBytesUntil $ff table.blankRow

        ret
.ends

;====
; Draws an ascii asterisk in the given column and row
;====
.macro "table.drawIndicator" args column row
    tilemap.setColRow column, row
    tilemap.writeBytes table.asciiAsterisk 1
.endm
