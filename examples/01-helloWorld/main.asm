;====
; SMSLib Hello World example
;====
.sdsctag 1.10, "smslib Hello World", "smslib Hello World example based on Maxim's tutorial", "lajohnston"

;====
; Import smslib
;====
.incdir "../../"            ; back to smslib directory
.include "smslib.asm"       ; base library
.include "mapper/basic.asm" ; memory mapper
.include "palette.asm"      ; handles colors
.include "patterns.asm"     ; handles patterns (tile images)
.include "tilemap.asm"      ; handles on-screen tilemap
.include "vdpreg.asm"       ; handles vdp settings
.include "boot.asm"         ; initialise system and smslib modules

;====
; Initialise program
;====
.section "init" free
    init:
        ; Load palette
        palette.setSlot 0           ; point to first color slot
        palette.load paletteData, 2 ; load 2 colors from 'paletteData' (see assets below)

        ; Load font tiles
        patterns.setSlot 0          ; point to first pattern slot
        patterns.load fontData, 95  ; load 95 patterns from 'fontData' (see assets below)

        ; Display font tiles on screen
        tilemap.setSlot 0, 0                ; Set tilemap slot x0, y0 (top left)
        tilemap.loadBytesUntil $ff message  ; Load data from 'message' until reaching terminator ($ff) byte

        ; Enable the display
        vdpreg.enableDisplay

        ; Freeze with infinite loop
        -: jr -
.ends

;====
; Assets
;====

; Maps ASCII data to bytes (see wla-dx docs)
.asciitable
    map " " to "~" = 0
.enda

.section "assets" free
    paletteData:
        palette.rgb 0, 0, 0         ; black
        palette.rgb 255, 255, 255   ; white

    fontData:
        .incdir "."
        .incbin "font.bin"

    message:
        .asc "Hello, world!"    ; possible because we set asciitable earlier
        .db $ff                 ; terminator byte
.ends
