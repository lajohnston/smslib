;====
; SMSLib Joypad Input Example
;
; This demo detects user input (pressed, current and held) and displays the
; result in a table on the screen
;====
.sdsctag 1.10, "smslib input", "smslib input tutorial", "lajohnston"

; Import smslib
.define interrupts.HANDLE_VBLANK 1  ; enable VBlank handling in interrupts.asm
.define input.ENABLE_PORT_2         ; enable reading port 2
.incdir "../../src"                 ; point to smslib directory
.include "smslib.asm"               ; base library
.incdir "."                         ; return to current directory

; Table
.include "table.asm"

;====
; Initialise the example
;====
.section "init" free
    init:
        call table.draw

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

        ; Reset table with blank values
        call table.reset

        ;===
        ; Update the columns to show which of the following condition(s)
        ; applies to each button
        ;===
        call detectPressed  ; indicate buttons that have just been pressed this frame
        call detectCurrent  ; indicate buttons that are currently pressed
        call detectHeld     ; indicate buttons that were pressed last frame and this frame
        call detectReleased ; indicate buttons that were pressed last frame but have just been released

        ; End VBlank handler
        interrupts.endVBlank
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
                table.drawIndicator PRESSED_INDICATOR_COLUMN, UP_ROW
                jp +
            _down:
                table.drawIndicator PRESSED_INDICATOR_COLUMN, DOWN_ROW
        +:

        ; Check if either LEFT or RIGHT have just been pressed
        input.ifXDirPressed _left, _right, +
            _left:
                table.drawIndicator PRESSED_INDICATOR_COLUMN, LEFT_ROW
                jp +
            _right:
                table.drawIndicator PRESSED_INDICATOR_COLUMN, RIGHT_ROW
        +:

        ; Check if BUTTON 1 has just been pressed
        input.ifPressed input.BUTTON_1, +
            table.drawIndicator PRESSED_INDICATOR_COLUMN, BUTTON_1_ROW
        +:

        ; Check if BUTTON 2 has just been pressed
        input.ifPressed input.BUTTON_2, +
            table.drawIndicator PRESSED_INDICATOR_COLUMN, BUTTON_2_ROW
        +:

        ; Check if both UP and BUTTON 1 have been pressed
        input.ifPressed input.UP, input.BUTTON_1, +
            table.drawIndicator PRESSED_INDICATOR_COLUMN, COMBO_ROW
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
                table.drawIndicator CURRENT_INDICATOR_COLUMN, UP_ROW
                jp +
            _down:
                table.drawIndicator CURRENT_INDICATOR_COLUMN, DOWN_ROW
        +:

        ; Check if either LEFT or RIGHT are currently pressed down
        input.ifXDir _left, _right, +
            _left:
                table.drawIndicator CURRENT_INDICATOR_COLUMN, LEFT_ROW
                jp +
            _right:
                table.drawIndicator CURRENT_INDICATOR_COLUMN, RIGHT_ROW
        +:

        ; Check if BUTTON_1 is currently pressed down
        input.if input.BUTTON_1, +
            table.drawIndicator CURRENT_INDICATOR_COLUMN, BUTTON_1_ROW
        +:

        ; Check if BUTTON_2 is currently pressed down
        input.if input.BUTTON_2, +
            table.drawIndicator CURRENT_INDICATOR_COLUMN, BUTTON_2_ROW
        +:

        ; Check if both UP and BUTTON 1 have been pressed
        input.if input.UP, input.BUTTON_1, +
            table.drawIndicator CURRENT_INDICATOR_COLUMN, COMBO_ROW
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
                table.drawIndicator HELD_INDICATOR_COLUMN, UP_ROW
                jp +
            _down:
                table.drawIndicator HELD_INDICATOR_COLUMN, DOWN_ROW
        +:

        ; Check if either LEFT or RIGHT are currently held
        input.ifXDirHeld _left, _right, +
            _left:
                table.drawIndicator HELD_INDICATOR_COLUMN, LEFT_ROW
                jp +
            _right:
                table.drawIndicator HELD_INDICATOR_COLUMN, RIGHT_ROW
        +:

        ; Check if BUTTON_1 is currently held
        input.ifHeld input.BUTTON_1, +
            table.drawIndicator HELD_INDICATOR_COLUMN, BUTTON_1_ROW
        +:

        ; Check if BUTTON_2 is currently held
        input.ifHeld input.BUTTON_2, +
            table.drawIndicator HELD_INDICATOR_COLUMN, BUTTON_2_ROW
        +:

        ; Check if both UP and BUTTON 1 have been held since the previous frame
        input.ifHeld input.UP, input.BUTTON_1, +
            table.drawIndicator HELD_INDICATOR_COLUMN, COMBO_ROW
        +:

        ret
.ends

;====
; Uses the if..released macros to detect when a button is has just been released,
; and indicates this with a '*' character in the table
;====
.section "detectReleased" free
    detectReleased:
        ; Check if either UP or DOWN were released
        input.ifYDirReleased _up, _down, +
            _up:
                table.drawIndicator RELEASED_INDICATOR_COLUMN, UP_ROW
                jp +
            _down:
                table.drawIndicator RELEASED_INDICATOR_COLUMN, DOWN_ROW
        +:

        ; Check if either LEFT or RIGHT were released
        input.ifXDirReleased _left, _right, +
            _left:
                table.drawIndicator RELEASED_INDICATOR_COLUMN, LEFT_ROW
                jp +
            _right:
                table.drawIndicator RELEASED_INDICATOR_COLUMN, RIGHT_ROW
        +:

        ; Check if BUTTON_1 was released
        input.ifReleased input.BUTTON_1, +
            table.drawIndicator RELEASED_INDICATOR_COLUMN, BUTTON_1_ROW
        +:

        ; Check if BUTTON_2 was released
        input.ifReleased input.BUTTON_2, +
            table.drawIndicator RELEASED_INDICATOR_COLUMN, BUTTON_2_ROW
        +:

        ; Check if both UP and BUTTON 1 were released
        input.ifReleased input.UP, input.BUTTON_1, +
            table.drawIndicator RELEASED_INDICATOR_COLUMN, COMBO_ROW
        +:

        ret
.ends
