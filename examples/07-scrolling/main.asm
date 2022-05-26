;====
; SMSLib tilemap scrolling example
;====
.sdsctag 1.10, "smslib tilemap scrolling", "smslib tilemap scrolling example", "lajohnston"

;====
; Import smslib
;====
.incdir "../../"            ; point to smslib directory
.include "smslib.asm"
.incdir "."                 ; point back to current working directory

;====
; Define asset data
;====
.define MAP_COLS 64

.section "assets" free
    paletteData:
        .incbin "../assets/tilemap/palette.bin" fsize paletteDataSize

    patternData:
        .incbin "../assets/tilemap/patterns.bin" fsize patternDataSize

    tilemapData:
        .incbin "../assets/tilemap/tilemap.bin" fsize tilemapDataSize
.ends

;====
; Initialise program
;
; SMSLib will jump to 'init' label after initialising the system
;====
.section "init" free
    init:
        ; Load palette
        palette.setSlot 0
        palette.load paletteData, paletteDataSize

        ; Load font tiles
        patterns.setSlot 0
        patterns.load patternData, patternDataSize

        ; Draw initial screen of tiles
        tilemap.setColRow 0, 0      ; set write address to col 0, row 0
        ld hl, tilemapData          ; point to top left of our tilemap
        ld b, tilemap.VISIBLE_ROWS  ; number of rows to output
        ld a, MAP_COLS * 2          ; number of full columns * 2 (2 bytes per tile)
        tilemap.loadRawRows         ; load a full screen of rows

        ; Enable the display
        vdp.enableDisplay

        ; End the program
        -: jp -
.ends
