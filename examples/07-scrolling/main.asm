;====
; SMSLib tilemap scrolling example
;====
.sdsctag 1.10, "smslib tilemap scrolling", "smslib tilemap scrolling example", "lajohnston"

;====
; Import smslib
;====
.define interrupts.handleVBlank 1   ; enable VBlanks (see VBlank example)

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
; RAM
;====
.ramsection "ram" slot mapper.RAM_SLOT
    ram.tilemapPointer: dw
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

        ; Store starting tilemapPointer
        ld hl, tilemapData
        ld (ram.tilemapPointer), hl

        ; Draw initial screen of tiles
        tilemap.reset               ; set scroll values to 0
        tilemap.setColRow 0, 0      ; set write address to col 0, row 0
        ld hl, (ram.tilemapPointer) ; load pointer to top left of our tilemap
        ld b, tilemap.VISIBLE_ROWS  ; number of rows to output
        ld a, MAP_COLS * 2          ; number of full columns * 2 (2 bytes per tile)
        tilemap.loadRawRows         ; load a full screen of rows

        ; Enable the display
        vdp.startBatch
            vdp.enableDisplay
            vdp.enableVBlank

            ; Left column gets filled with junk when scrolling, so best to hide it
            vdp.hideLeftColumn
        vdp.endBatch

        interrupts.enable

        ; Start the update loop
        jp update
.ends

;====
; The update loop
;====
.section "update" free
    update:
        ; Wait for VBlank to finish
        interrupts.waitForVBlank

        ;====
        ; Adjust tilemap based on joypad input direction
        ;====
        input.readPort1         ; read the state of joypad 1
        input.loadADirX         ; load A with x direction (-1 = left, 1 = right; 0 = none)
        tilemap.adjustXPixels   ; adjust tilemap x by this many pixels

        ;====
        ; Adjust the tilemap pointer based on scroll direction
        ;====
        ld hl, ram.tilemapPointer

        tilemap.ifColScroll _left, _right, +
            _left:
                ; Dec ram.tilemapPointer by 1 tile (2-bytes)
                dec (hl)
                dec (hl)
                jp +        ; jump over _right handler

            _right:
                ; Inc ram.tilemapPointer by 1 tile (2-bytes)
                inc (hl)
                inc (hl)
        +:

        jp update   ; start loop again
.ends

;====
; The VBlank routine where we'll apply changes to the VDP
;====
.section "render" free
    interrupts.onVBlank:
        tilemap.updateScrollRegisters   ; apply the buffered scroll registers
        interrupts.endVBlank
.ends