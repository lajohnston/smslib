;====
; SMSLib Joypad Input Example
;
; This demo detects user input (pressed, current and held) and displays the
; result in a table on the screen
;====
.sdsctag 1.10, "smslib input", "smslib input tutorial", "lajohnston"

; Import smslib
.define interrupts.handleVBlank 1   ; enable VBlank handling in interrupts.asm
.incdir "../../"                    ; point to smslib directory
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

    ; Table template. We'll update this each frame
    template:
        .asc "          Pressed Current Held  "
        .asc "                                "
        .asc " Up       ( )     ( )     ( )   "
        .asc " Down     ( )     ( )     ( )   "
        .asc " Left     ( )     ( )     ( )   "
        .asc " Right    ( )     ( )     ( )   "
        .asc "                                "
        .asc " Button 1 ( )     ( )     ( )   "
        .asc " Button 2 ( )     ( )     ( )   "
        .asc "                                "
        .asc " Up and 1 ( )     ( )     ( )   "
        .db $ff ; terminator

    ; We'll add an asterisk in between the brackets in the template string,
    ; indicating which condition has been met
    asciiAsterisk:
        .asc '*'
.ends

; The starting row the render the table from
.define TABLE_ROW_OFFSET = 6

; The indicator tile columns for each condition (Pressed, Current, Held)
.define PRESSED_INDICATOR_COLUMN = 11
.define CURRENT_INDICATOR_COLUMN = PRESSED_INDICATOR_COLUMN + 8
.define HELD_INDICATOR_COLUMN = CURRENT_INDICATOR_COLUMN + 8

; The row number for each button
.define UP_ROW = TABLE_ROW_OFFSET + 2
.define DOWN_ROW = TABLE_ROW_OFFSET + 3
.define LEFT_ROW = TABLE_ROW_OFFSET + 4
.define RIGHT_ROW = TABLE_ROW_OFFSET + 5
.define BUTTON_1_ROW = TABLE_ROW_OFFSET + 7
.define BUTTON_2_ROW = TABLE_ROW_OFFSET + 8
.define COMBO_ROW = TABLE_ROW_OFFSET + 10

;====
; Initialise the example
;====
.section "init" free
    init:
        palette.setIndex 0
        palette.writeBytes fontPalette 2

        patterns.setIndex 0
        patterns.writeBytes fontPatterns, fontPatternsSize

        vdp.startBatch
            vdp.enableDisplay
            vdp.enableVBlank
        vdp.endBatch

        interrupts.enable

        -:
            halt    ; wait for next VBlank
        jp -        ; infinite loop
.ends

;====
; interrupts.onVBlank is called by interrupts.asm 50/60x a second (PAL/NTSC)
; We'll check the input each time and update the display accordingly
; (see vblank example)
;====
.section "vBlank" free
    interrupts.onVBlank:
        ; Read input from port 1
        ; You can also try this with input.readPort2
        input.readPort1

        ; Redraw table with blank values
        call drawBlankTable

        ;===
        ; Update the columns to show which of the following condition(s)
        ; applies to each button
        ;===
        call detectPressed  ; indicate buttons that have just been pressed this frame
        call detectCurrent  ; indicate buttons that are currently pressed
        call detectHeld     ; indicate buttons that were pressed last frame and this frame

        ; End VBlank handler
        interrupts.endVBlank
.ends

;====
; Draws an ascii asterisk in the given column and row
;====
.macro "writeAsterisk" args column row
    tilemap.setColRow column, row
    tilemap.writeBytes asciiAsterisk 1
.endm

;====
; Draws the blank table with none of the indicators populated
;====
.section "drawBlankTable" free
    drawBlankTable:
        tilemap.setColRow 0, TABLE_ROW_OFFSET
        tilemap.writeBytesUntil $ff, template
        ret
.ends

;====
; Uses the if..pressed macros to detect when a button has just been pressed
; this frame, and indicate this with a '*' character. This only occurs for
; 1 frame so the indicator will flash once each time the button is pressed
;====
.section "detectPressed" free
    detectPressed:
        ; Check if either UP or DOWN have just been pressed
        input.ifYDirPressed _up, _down, +
            _up:
                writeAsterisk PRESSED_INDICATOR_COLUMN, UP_ROW
                jp +
            _down:
                writeAsterisk PRESSED_INDICATOR_COLUMN, DOWN_ROW
        +:

        ; Check if either LEFT or RIGHT have just been pressed
        input.ifXDirPressed _left, _right, +
            _left:
                writeAsterisk PRESSED_INDICATOR_COLUMN, LEFT_ROW
                jp +
            _right:
                writeAsterisk PRESSED_INDICATOR_COLUMN, RIGHT_ROW
        +:

        ; Check if BUTTON 1 has just been pressed
        input.ifPressed input.BUTTON_1, +
            writeAsterisk PRESSED_INDICATOR_COLUMN, BUTTON_1_ROW
        +:

        ; Check if BUTTON 2 has just been pressed
        input.ifPressed input.BUTTON_2, +
            writeAsterisk PRESSED_INDICATOR_COLUMN, BUTTON_2_ROW
        +:

        ; Check if both UP and BUTTON 1 have been pressed
        input.ifPressed input.UP, input.BUTTON_1, +
            writeAsterisk PRESSED_INDICATOR_COLUMN, COMBO_ROW
        +:

        ret
.ends

;====
; Uses the 'if' macros to detect when a button is currently pressed, and
; indicate this with a '*' character. Unlike the 'pressed' condition this
; indicator will stay on until the button is released
;====
.section "detectCurrent" free
    detectCurrent:
        ; Check if either UP or DOWN are currently pressed down
        input.ifYDir _up, _down, +
            _up:
                writeAsterisk CURRENT_INDICATOR_COLUMN, UP_ROW
                jp +
            _down:
                writeAsterisk CURRENT_INDICATOR_COLUMN, DOWN_ROW
        +:

        ; Check if either LEFT or RIGHT are currently pressed down
        input.ifXDir _left, _right, +
            _left:
                writeAsterisk CURRENT_INDICATOR_COLUMN, LEFT_ROW
                jp +
            _right:
                writeAsterisk CURRENT_INDICATOR_COLUMN, RIGHT_ROW
        +:

        ; Check if BUTTON_1 is currently pressed down
        input.if input.BUTTON_1, +
            writeAsterisk CURRENT_INDICATOR_COLUMN, BUTTON_1_ROW
        +:

        ; Check if BUTTON_2 is currently pressed down
        input.if input.BUTTON_2, +
            writeAsterisk CURRENT_INDICATOR_COLUMN, BUTTON_2_ROW
        +:

        ret
.ends

;====
; Uses the if..held macros to detect when a button is currently pressed and
; was also pressed in the last frame, then indicate this with a '*' character.
;
; If you tap the button fast enough you'll see that the 'pressed' and 'current'
; indicators highlight but not the 'held' indicator. From then on the held
; indicator will stay on until the button is released
;====
.section "detectHeld" free
    detectHeld:
        ; Check if either UP or DOWN are currently held
        input.ifYDirHeld _up, _down, +
            _up:
                writeAsterisk HELD_INDICATOR_COLUMN, UP_ROW
                jp +
            _down:
                writeAsterisk HELD_INDICATOR_COLUMN, DOWN_ROW
        +:

        ; Check if either LEFT or RIGHT are currently held
        input.ifXDirHeld _left, _right, +
            _left:
                writeAsterisk HELD_INDICATOR_COLUMN, LEFT_ROW
                jp +
            _right:
                writeAsterisk HELD_INDICATOR_COLUMN, RIGHT_ROW
        +:

        ; Check if BUTTON_1 is currently held
        input.ifHeld input.BUTTON_1, +
            writeAsterisk HELD_INDICATOR_COLUMN, BUTTON_1_ROW
        +:

        ; Check if BUTTON_2 is currently held
        input.ifHeld input.BUTTON_2, +
            writeAsterisk HELD_INDICATOR_COLUMN, BUTTON_2_ROW
        +:

        ret
.ends
