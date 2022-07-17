;====
; SMSLib scrolling tilemap example
;
; Part 1 of the tilemap tutorial demonstrates how to scroll the tilemap and
; draw new columns and rows when required. Use the input directions to scroll
; the tilemap. This example will simply load rows and columns with arrows
; pointing to the scroll direction
;====
.sdsctag 1.10, "smslib tilemap scrolling", "smslib tilemap scrolling example", "lajohnston"

;====
; Import smslib
;====
.define interrupts.handleVBlank 1   ; enable VBlanks (see VBlank example)
.incdir "../../"                    ; point to smslib directory
.include "smslib.asm"
.incdir "."                         ; point back to current working directory

;====
; Define asset data
;====
.define DEFAULT_PATTERN 0
.define UP_ARROW_PATTERN 1
.define DOWN_ARROW_PATTERN 2
.define LEFT_ARROW_PATTERN 3
.define RIGHT_ARROW_PATTERN 4

.section "assets" free
    paletteData:
        .incbin "../assets/tilemapArrows/palette.bin" fsize paletteDataSize

    patternData:
        .incbin "../assets/tilemapArrows/patterns.bin" fsize patternDataSize

    initialScreen:
        .repeat tilemap.VISIBLE_ROWS * tilemap.VISIBLE_COLS
            .db DEFAULT_PATTERN
            .db 0   ; attributes
        .endr

    scrollUpRow:
        .repeat tilemap.VISIBLE_COLS
            .db UP_ARROW_PATTERN
            .db 0   ; attributes
        .endr

    scrollDownRow:
        .repeat tilemap.VISIBLE_COLS
            .db DOWN_ARROW_PATTERN
            .db 0   ; attributes
        .endr

    scrollLeftCol:
        .repeat tilemap.VISIBLE_ROWS
            .db LEFT_ARROW_PATTERN
            .db 0   ; attributes
        .endr

    scrollRightCol:
        .repeat tilemap.VISIBLE_ROWS
            .db RIGHT_ARROW_PATTERN
            .db 0   ; attributes
        .endr
.ends

;====
; Initialise program
;====
.section "init" free
    ; SMSLib will jump to the init label after booting the system
    init:
        ; Load palette and patterns
        palette.setSlot 0
        palette.load paletteData, paletteDataSize
        patterns.setSlot 0
        patterns.load patternData, patternDataSize

        ; Draw initial screen of tiles (see tilemap.loadRows in tilemap.asm)
        tilemap.reset                   ; initialise scroll values to 0
        tilemap.setColRow 0, 0          ; set write address to col 0, row 0
        ld hl, initialScreen            ; point to default tilemap data
        ld d, tilemap.VISIBLE_ROWS      ; number of rows to output
        ld e, tilemap.COL_SIZE_BYTES    ; bytes to add to the map pointer each row
        tilemap.loadRows             ; load rows

        ; Enable the display
        vdp.startBatch
            vdp.enableDisplay
            vdp.enableVBlank

            ; Left column gets filled with junk when scrolling, so best to hide it
            vdp.hideLeftColumn
        vdp.endBatch

        ; Enable interrupts then start the update loop
        interrupts.enable
        jp update
.ends

;====
; The update loop that runs each frame during active display
;====
.section "update" free
    update:
        ; Wait for the next VBlank to finish
        interrupts.waitForVBlank

        ; Adjust tilemap based on joypad input direction
        input.readPort1         ; read the state of joypad 1

        input.loadADirX         ; load A with x direction (-1 = left, 1 = right; 0 = none)
        tilemap.adjustXPixels   ; adjust tilemap x by that many pixels

        input.loadADirY         ; load A with y direction (-1 = up, 1 = down; 0 = none)
        tilemap.adjustYPixels   ; adjust tilemap y by that many pixels

        tilemap.calculateScroll ; calculate these adjustments

        jp update               ; start loop again
.ends

;====
; The VBlank routine where we'll apply changes to the VDP
;====
.section "render" free
    interrupts.onVBlank:
        ; Apply the buffered scroll registers
        tilemap.updateScrollRegisters

        tilemap.ifRowScroll, _up, _down, +
            _up:
                tilemap.setRowScrollSlot
                ld hl, scrollUpRow
                tilemap.loadRow
                jp +
            _down:
                tilemap.setRowScrollSlot
                ld hl, scrollDownRow
                tilemap.loadRow
        +:

        tilemap.ifColScroll _left, _right, +
            _left:
                ld hl, scrollLeftCol
                tilemap.loadScrollCol
                jp +    ; skip _right
            _right:
                ld hl, scrollRightCol
                tilemap.loadScrollCol
        +:

        ; Mark the end of the VBlank handler
        interrupts.endVBlank
.ends
