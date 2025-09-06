;====
; SMSLib Hello World example
;====
.sdsctag 1.10, "smslib Hello World", "smslib Hello World example based on Maxim's tutorial", "lajohnston"

;====
; Import smslib
;====
.incdir "../../src"         ; point to smslib directory
.include "smslib.asm"
.incdir "."                 ; point back to current working directory

;====
; Define asset data
;====

; Map ASCII data to byte values so we can use .asc later (see wla-dx docs)
.asciitable
    map " " to "~" = 0
.enda

.section "assets" free
    paletteData:
        palette.rgb 0, 0, 0         ; black
        palette.rgb 255, 255, 255   ; white

    fontData:
        ; font.bin contains uncompressed graphics representing the letters of the
        ; alphabet. Here we include it and set fontDataSize to its total size
        .incbin "../assets/font.bin" fsize fontDataSize

    message:
        .asc "Hello, world!"
        .db $ff                     ; terminator byte
.ends

;====
; Initialise program
;
; SMSLib will jump to 'init' label after initialising the system
;====
.section "init" free
    init:
        ; Load palette
        palette.setIndex 0                  ; point to first color index
        palette.writeSlice paletteData, 2   ; write 2 colors from paletteData

        ; Load font tiles
        patterns.setIndex 0                         ; point to first pattern index
        patterns.writeBytes fontData, fontDataSize  ; write uncompressed font data into pattern VRAM

        ; Display font tiles on screen
        tilemap.setColRow 0, 0              ; set tilemap index x0, y0 (top left)
        tilemap.writeBytesUntil $ff message ; write data from 'message' until reaching terminator ($ff) byte

        ; Enable the display
        vdp.enableDisplay

        ; End program with infinite loop
        -: jr -
.ends
