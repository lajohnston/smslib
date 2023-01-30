;====
; SMSLib scrolling metatilemap example
;
; Like the previous example we will have a tilemap that is larger than the
; screen and can be scrolled using the directional input. However, this time
; we will use the scroll/metatiles.asm handler which will build the tilemap
; using 'metatiles', tiles that are grouped together and referred to with a
; 1-byte reference. This shrinks the size down considerably (a 2x2 metatile
; would usually use 8 bytes, so 8x more) and the tilemap becomes small enough
; to be stored uncompressed and modified in RAM.
;====
.sdsctag 1.10, "smslib metatile scrolling", "smslib metatile scrolling example", "lajohnston"

;====
; Import smslib
;====
.define interrupts.handleVBlank 1   ; enable VBlanks (see VBlank example)
.incdir "../../"                    ; point to smslib directory
.include "smslib.asm"

; Set the size (each value can be 2, 4, 8, 16)
; Try changing these values and see for your yourself:
.define scroll.metatiles.COLS_PER_METATILE 4
.define scroll.metatiles.ROWS_PER_METATILE 4
.include "scroll/metatiles.asm"     ; a metatile scroll handler

.incdir "."                         ; point back to current working directory

;====
; Define asset data
;====

; Scroll speed in pixels per axis (should be between 0 and 8 inclusive)
.define SCROLL_SPEED 2

;====
; A set of metatile definitions consisting of raw tile data stored sequentally.
; Ensure these are aligned to the scroll.metatiles.DEFS_ALIGN value.
;====
.section "metatileDefs" free align scroll.metatiles.DEFS_ALIGN
    metatileDefs:
        .include "../assets/metatiles/metatileDefs.asm"
.ends

;====
; The metatile map, consisting of a grid of 1-byte refereces to the metatile
; definitions. The width and height are variable at runtime allowing a variety
; of map sizes. The max width in metatiles is 255. The max height is the set
; scroll.metatiles.MAX_MAP_BYTES value (defaults to 4096) divided by this map
; width
;====
.define MAP_WIDTH_METATILES     64  ; map width in metatiles
.define MAP_HEIGHT_METATILES    64  ; map height in metatiles

.section "metatileMap"
    metatileMap:
        .include "../assets/metatiles/metatileMap.asm"
    metatileMapEnd:
.ends

;====
; Palette and patterns
;====
.section "assets" free
    paletteData:
        .incbin "../assets/metatiles/palette.bin" fsize paletteDataSize

    patternData:
        .incbin "../assets/metatiles/patterns.bin" fsize patternDataSize
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

        ;===
        ; Load the metatile map into RAM
        ; An actual game would have compressed data that it decompresses to RAM
        ; but for this example we'll just copy it from ROM to RAM
        ;===
        ld hl, metatileMap                  ; set HL to the map in ROM
        scroll.metatiles.loadDEMap          ; set DE to the map in RAM
        ld bc, metatileMapEnd - metatileMap ; number of bytes to write
        ldir                                ; copy from (HL) to (DE) until BC is 0

        ; Set the location of the metatile definitions
        ld hl, metatileDefs
        scroll.metatiles.setDefs

        ; Initialise map (offset x0, y0)
        ld a, MAP_WIDTH_METATILES           ; set map width (in metatiles)
        ld d, MAP_HEIGHT_METATILES          ; the map's height
        ld b, 0                             ; metatile col offset (0 = left)
        ld c, 0                             ; metatile row offset (0 = top)
        scroll.metatiles.init               ; draw the inital screen

        ; Enable the display
        vdp.startBatch
            vdp.enableDisplay
            vdp.enableVBlank

            ; Left column gets filled with junk when scrolling, so best hide it
            vdp.hideLeftColumn
        vdp.endBatch

        ; Enable interrupts then start the update loop
        interrupts.enable
        jp update
.ends

;====
; The update loop that runs each frame during the active display
;====
.section "update" free
    update:
        ; Wait for the next VBlank to finish
        interrupts.waitForVBlank

        ;===
        ; Adjust tilemap based on joypad input direction
        ;===
        input.readPort1                 ; read the state of joypad 1

        input.loadADirX SCROLL_SPEED    ; load A with X direction * scroll speed
        scroll.metatiles.adjustXPixels  ; adjust tilemap X by that many pixels

        input.loadADirY SCROLL_SPEED    ; load A with Y direction * scroll speed
        scroll.metatiles.adjustYPixels  ; adjust tilemap Y by that many pixels

        ; Update RAM buffers (doesn't update VDP/VRAM yet)
        scroll.metatiles.update

        jp update   ; start loop again
.ends

;====
; The VBlank routine where we'll apply changes to the VDP
;====
.section "render" free
    interrupts.onVBlank:
        ; Apply scroll changes to the VDP/VRAM
        scroll.metatiles.render

        ; Mark the end of the VBlank handler
        interrupts.endVBlank
.ends
