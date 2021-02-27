;====
; SMSLib Hello World example
;====
.sdsctag 1.10, "smslib Hello World", "smslib Hello World example based on Maxim's tutorial", "lajohnston"

;====
; Import smslib
;====
.incdir "../../"            ; back to smslib directory
.include "smslib.asm"

;====
; Initialise program
;
; SMSLib will jump to 'init' label after initialising the system
;====
.section "init" free
    init:
        ; Load palette
        palette.setSlot 0                   ; point to first color slot
        palette.loadSlice paletteData, 2    ; load 2 colors from paletteData

        ; Load font tiles
        patterns.setSlot 0          ; point to first pattern slot
        patterns.load fontData, 95  ; load 95 patterns from 'fontData' (see assets below)

        ; Display font tiles on screen
        tilemap.setSlot 0, 0                ; Set tilemap slot x0, y0 (top left)
        tilemap.loadBytesUntil $ff message  ; Load data from 'message' until reaching terminator ($ff) byte

        ; Enable the display
        vdp.enableDisplay

        ; End program with infinite loop
        -: jr -
.ends

;====
; Assets
;====

; Maps ASCII data to bytes so we can use .asc later (see wla-dx docs)
.asciitable
    map " " to "~" = 0
.enda

.section "assets" free
    paletteData:
        palette.rgb 0, 0, 0         ; black
        palette.rgb 255, 255, 255   ; white

    fontData:
        .incdir "."                 ; back to current working directory
        .incbin "font.bin"

    message:
        .asc "Hello, world!"
        .db $ff                     ; terminator byte
.ends
