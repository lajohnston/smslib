;====
; SMSLib scrolling tilemap example
;
; We will utilise the scroll.tiles module to maintain a tilemap that is larger
; than the screen. Each frame we will adjust its scroll position based on the
; directional input from the controller.
;====
.sdsctag 1.10, "smslib tilemap scrolling", "smslib tilemap scrolling example", "lajohnston"

;====
; Import smslib
;====
.incdir "../../src"                     ; point to smslib directory
.include "smslib.asm"

; Include a scroll handler that uses raw tile data
.include "scroll/tiles.asm"

.incdir "."                         ; point back to current working directory

;====
; Define asset data
;====

; The number of tile rows and columns in our full tilemap
.define MAP_COLS 64
.define MAP_ROWS 64

; Scroll speed in pixels per axis (should be between 0 and 8 inclusive)
.define SCROLL_SPEED 1

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
;====
.section "init" free
    ; SMSLib will jump to the init label after booting the system
    init:
        ; Load palette and patterns
        palette.setIndex 0
        palette.writeBytes paletteData, paletteDataSize
        patterns.setIndex 0
        patterns.writeBytes patternData, patternDataSize

        ; Initialise map (offset x0, y0)
        scroll.tiles.init tilemapData MAP_COLS MAP_ROWS 0 0

        ; Enable the display
        vdpSettings.startBatch
            vdpSettings.enableDisplay

            ; Left column gets filled with junk when scrolling, so best to hide it
            vdpSettings.hideLeftColumn
        vdpSettings.endBatch

        ; Start the update loop
        jp update
.ends

;====
; The update loop that runs each frame during active display
;====
.section "update" free
    update:
        ; Adjust tilemap based on joypad input direction
        input.readPort1             ; read the state of joypad 1

        input.loadDirX "a", SCROLL_SPEED    ; load A with X direction * scroll speed
        scroll.tiles.adjustXPixels          ; adjust tilemap X by that many pixels

        input.loadDirY "a", SCROLL_SPEED    ; load A with Y direction * scroll speed
        scroll.tiles.adjustYPixels          ; adjust tilemap Y by that many pixels

        ; Buffer changes in RAM (doesn't update VDP/VRAM yet)
        scroll.tiles.update

        ; Wait for the next VBlank, where we can safely write to the VDP
        interrupts.waitForVBlank

        ; Apply scroll changes to the VDP/VRAM
        scroll.tiles.render

        jp update   ; start loop again
.ends
