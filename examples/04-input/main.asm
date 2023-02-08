;====
; SMSLib Joypad Input Example
;
; This demo detects user input and displays the result on the screen. Renders
; text on the screen stating which buttons are being pressed
;====
.sdsctag 1.10, "smslib input", "smslib input tutorial", "lajohnston"

; Import smslib
.define interrupts.handleVBlank 1   ; enable VBlank handling in interrupts.asm
.incdir "../../"                    ; back to smslib directory
.include "smslib.asm"               ; base library
.incdir "."                         ; return to current directory

;====
; Assets
;====

; Map ASCII data to byte values so we can use .asc later (see wla-dx docs)
.asciitable
    map " " to "~" = 0
.enda

.section "assets" free
    fontPalette:
        palette.rgb 0, 0, 0
        palette.rgb 170, 85, 170

    fontPatterns:
        .incbin "../assets/font.bin" fsize fontPatternsSize

    ; Ascii for -1, 0, 1, padded to 2 chars to keep alignment
    asciiMinusOne:
        .asc "-1"

    asciiZero:
        .asc " 0"

    asciiOne:
        .asc " 1"

    ; Template string. We'll populate the values based on the buttons pressed
    template:
        .asc "         Dir X    :  0          "
        .asc "         Dir Y    :  0          "
        .asc "                                "
        .asc "         Button 1 :  0          "
        .asc "         Button 2 :  0          "
        .db $ff ; terminator
.ends

; Locations (columns, rows) of the values in the template text
.define VALUE_COLUMN = 20
.define ROW_OFFSET = 9
.define DIR_X_ROW = ROW_OFFSET
.define DIR_Y_ROW = ROW_OFFSET + 1
.define BUTTON_1_ROW = ROW_OFFSET + 3
.define BUTTON_2_ROW = ROW_OFFSET + 4

;====
; Initialise the example
;====
.section "init" free
    init:
        palette.setIndex 0
        palette.load fontPalette 2

        patterns.setSlot 0
        patterns.load fontPatterns, fontPatternsSize

        tilemap.setColRow 0, ROW_OFFSET
        tilemap.loadBytesUntil $ff, template

        vdp.startBatch
            vdp.enableDisplay
            vdp.enableVBlank
        vdp.endBatch

        interrupts.enable

        ; Stop program for the time being
        - jp -
.ends

.section "render" free
    ; interrupts.onVBlank is called by interrupts.asm 50/60x a second (PAL/NTSC)
    ; We'll check the input each time and update the display accordingly
    interrupts.onVBlank:
        ; Read input from port 1
        ; You can also try this with input.readPort2
        input.readPort1

        ;==
        ; Update X direction
        ;==
        tilemap.setColRow VALUE_COLUMN, DIR_X_ROW
        tilemap.loadBytes asciiZero, 2          ; set value to 0 by default

        ; If left is being pressed
        input.if input.LEFT, +
            tilemap.setColRow VALUE_COLUMN, DIR_X_ROW
            tilemap.loadBytes asciiMinusOne, 2  ; set to -1
        +:

        ; If right is being pressed
        input.if input.RIGHT, +
            tilemap.setColRow VALUE_COLUMN, DIR_X_ROW
            tilemap.loadBytes asciiOne, 2       ; set to 1
        +:

        ;==
        ; Update Y direction
        ;==
        tilemap.setColRow VALUE_COLUMN, DIR_Y_ROW
        tilemap.loadBytes asciiZero, 2          ; set value to 0 by default

        ; If up is being pressed
        input.if input.UP, +
            tilemap.setColRow VALUE_COLUMN, DIR_Y_ROW
            tilemap.loadBytes asciiMinusOne, 2  ; set to -1
        +:

        ; If down is being pressed
        input.if input.DOWN, +
            tilemap.setColRow VALUE_COLUMN, DIR_Y_ROW
            tilemap.loadBytes asciiOne, 2       ; set to 1
        +:

        ;==
        ; Update Button 1
        ;==
        tilemap.setColRow VALUE_COLUMN, BUTTON_1_ROW
        tilemap.loadBytes asciiZero, 2          ; set value to 0 by default

        input.if input.BUTTON_1, +
            tilemap.setColRow VALUE_COLUMN, BUTTON_1_ROW
            tilemap.loadBytes asciiOne, 2       ; set to 1
        +:

        ;==
        ; Update Button 2
        ;==
        tilemap.setColRow VALUE_COLUMN, BUTTON_2_ROW
        tilemap.loadBytes asciiZero, 2          ; set value to 0 by default

        input.if input.BUTTON_2, +
            tilemap.setColRow VALUE_COLUMN, BUTTON_2_ROW
            tilemap.loadBytes asciiOne, 2       ; set to 1
        +:

        ; End VBlank handler
        interrupts.endVBlank
.ends
