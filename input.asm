;===
; Input
;
; Reads and interprets joypad inputs
;====

.define input.ENABLED 1

; Dependencies
.ifndef utils.assert
    .include "./utils/assert.asm"
.endif

.include "./utils/ramSlot.asm"

; Constants
.define input.UP        %00000001
.define input.DOWN      %00000010
.define input.LEFT      %00000100
.define input.RIGHT     %00001000
.define input.BUTTON_1  %00010000
.define input.BUTTON_2  %00100000

.define input.UP_BIT        0
.define input.DOWN_BIT      1
.define input.LEFT_BIT      2
.define input.RIGHT_BIT     3
.define input.BUTTON_1_BIT  4
.define input.BUTTON_2_BIT  5

.define input.PORT_1    $dc
.define input.PORT_2    $dd

;====
; RAM section storing the last port that was read with either input.readPort1
; or input.readPort2
;====
.ramsection "input.ram.activePort" slot utils.ramSlot
    input.ram.activePort.current:   db
    input.ram.activePort.previous:  db
.ends

;====
; RAM section to store the previous input values for each port
;====
.ramsection "input.ram.previous" slot utils.ramSlot
    input.ram.previous.port1:    db
    input.ram.previous.port2:    db
.ends

;====
; Initialises the input handler in RAM
;====
.macro "input.init"
    ; Initialise all buttons to released
    xor a
    ld (input.ram.activePort.current), a
    ld (input.ram.activePort.previous), a
    ld (input.ram.previous.port1), a
    ld (input.ram.previous.port2), a
.endm

;====
; Reads the input from controller port 1 into the ram buffer
;
; The reset bits represent the buttons currently pressed
;
;       xx000000
;       |||||||*- Up
;       ||||||*-- Down
;       |||||*--- Left
;       ||||*---- Right
;       |||*----- Button 1
;       ||*------ Button 2
;       ** junk
;====
.macro "input.readPort1"
    ; Copy previous value of port 1 to activePort.previous
    ld a, (input.ram.previous.port1)        ; load previous.port1
    ld (input.ram.activePort.previous), a   ; store in activePort.previous

    ; Load current port 1 input and store in activePort.current
    in a, input.PORT_1                      ; load input
    xor $ff                                 ; invert so 1 = pressed and 0 = released
    ld (input.ram.activePort.current), a    ; store in activePort.current
    ld (input.ram.previous.port1), a        ; store in previous.port1 for next time
.endm

;====
; Reads the input from controller port 2 into the RAM buffer
; See input.readPort1 documentation for details
;====
.macro "input.readPort2"
    ; Copy previous value of port 2 to activePort.previous
    ld a, (input.ram.previous.port2)        ; load previous.port1
    ld (input.ram.activePort.previous), a   ; store in activePort.previous

    ; Retrieve up and down buttons, which are stored within the PORT_1 byte
    in a, input.PORT_1
    and %11000000                           ; clear port 1 buttons
    ld b, a                                 ; store in B (DU------)

    ; Read remaining buttons from PORT_2
    in a, input.PORT_2
    and %00001111                           ; reset misc. bits (----21RL)

    ; Combine into 1 byte (DU--21RL)
    or b

    ; Rotate left twice to match port 1 format
    rlca    ; rotate DU--21RL to U--21RLD
    rlca    ; rotate U--21RLD to --21RLDU

    ; Invert so 1 = pressed and 0 = released
    xor $ff

    ; Store in ram buffer
    ld (input.ram.activePort.current), a
    ld (input.ram.previous.port2), a        ; store in previous.port2 for next time
.endm

;====
; Load A with buttons that are pressed down this frame and were pressed down
; in the last frame
;
; @out  a   held buttons (--21RLDU)
;====
.macro "input.loadAHeld"
    ; Load current input into L and previous into H
    ld hl, (input.ram.activePort.current)
    ld a, l     ; load current into A
    and h       ; AND with previous
.endm

;====
; Check if a given button has been pressed
;
; @in   button  the button to check (input.UP, input.BUTTON_1 etc)
; @in   else    the address to jump to if the button is not pressed
;====
.macro "input.if" args button else
    ld a, (input.ram.activePort.current)
    and button
    jp z, else
.endm

;====
; Check if a given button has been pressed in both this frame and the previous
; frame
;
; @in   button  the button to check (input.UP, input.BUTTON_1 etc)
; @in   else    the address to jump to if the button has not been held
;====
.macro "input.ifHeld" args button else
    utils.assert.equals NARGS, 2, "input.asm \.: Unexpected number of arguments"
    utils.assert.range button, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
    utils.assert.label else, "input.asm \.: Invalid label argument"

    input.loadAHeld     ; load A with held buttons
    and button          ; check the given button

    ; jp to else label if button was not pressed in both this and previous frame
    jp z, else
.endm

;====
; Sets A with the input difference between this frame and last frame
;
; @out  a   the changed state for each button (--21RLDU)
;====
.macro "input.loadADiff"
    ; Load L with current input value and H with previous
    ld hl, (input.ram.activePort.current)
    ld a, l ; load current into A
    xor h   ; XOR with previous. The set bits are now buttons that have changed
.endm

;====
; Check if a given button has just been pressed this frame
;
; @in   button  the button to check (input.UP, input.BUTTON_1 etc)
; @in   else    the address to jump to if the button is either not pressed, or
;               if it was already pressed last frame
;====
.macro "input.ifPressed" args button else
    utils.assert.equals NARGS, 2, "input.asm \.: Unexpected number of arguments"
    utils.assert.range button, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
    utils.assert.label else, "input.asm \.: Invalid label argument"

    ; Load input difference between this frame and last frame
    input.loadADiff

    ; AND with current input; Set bits have changed AND are currently pressed
    and l

    and button      ; check button bit
    jp z, else      ; jp to else if the bit was not set
.endm

;====
; Jumps to the relevant label if either left or right are currently pressed
;
; @in   left    the label to continue to if LEFT is currently pressed
; @in   right   the label to jp to if RIGHT is currently pressed
; @in   else    the label to jp to if neither LEFT nor RIGHT are currently pressed
;====
.macro "input.ifXDir" args left right else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label left "input.asm \.: Invalid 'left' argument"
    utils.assert.label right "input.asm \.: Invalid 'right' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ld a, (input.ram.activePort.current)
    bit input.RIGHT_BIT, a  ; check RIGHT bit
    jp nz, right            ; jp to 'right' label if RIGHT is pressed

    bit input.LEFT_BIT, a   ; check LEFT bit
    jp z, else              ; jp to 'else' label if LEFT not pressed

    ; ...continue to 'left' label
.endm

;====
; Detects if either left or right have been pressed for this frame and the
; previous frame, and jumps to the relevant label if one has.
;
; @in   left    the label to continue to if LEFT is held
; @in   right   the label to jp to if RIGHT is held
; @in   else    the label to jp to if neither LEFT nor RIGHT are held
;====
.macro "input.ifXDirHeld" args left right else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label left "input.asm \.: Invalid 'left' argument"
    utils.assert.label right "input.asm \.: Invalid 'right' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    input.loadAHeld         ; load A with held buttons

    ; Check if RIGHT is held
    bit input.RIGHT_BIT, a  ; check RIGHT bit
    jp nz, right            ; jump to 'right' label if right is held

    ; Check if LEFT is held
    bit input.LEFT_BIT, a   ; check LEFT bit
    jp z, else              ; jump to 'else' label if left is not held

    ; otherwise LEFT was held, so continue to left label
.endm

;====
; Detects if either left or right have just been pressed this frame, i.e. the
; button was released last frame but is now pressed. Jumps to the relevant
; label if it has.
;
; @in   left    the label to continue to if LEFT has just been pressed
; @in   right   the label to jp to if RIGHT had just been pressed
; @in   else    the label to jp to if neither LEFT nor RIGHT have just been pressed
;====
.macro "input.ifXDirPressed" args left right else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label left "input.asm \.: Invalid 'left' argument"
    utils.assert.label right "input.asm \.: Invalid 'right' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load input difference between this frame and last frame
    input.loadADiff

    ; AND with current input; Set bits have changed AND are currently pressed
    and l

    ; Check if RIGHT has just been pressed
    bit input.RIGHT_BIT, a  ; check RIGHT bit
    jp nz, right            ; jump to 'right' label if right is pressed

    ; Check if LEFT has just been pressed
    bit input.LEFT_BIT, a   ; check LEFT bit
    jp z, else              ; jump to 'else' label if left is not pressed

    ; otherwise LEFT was pressed, so continue to left label
.endm

;====
; Jumps to the relevant label if either up or down are currently pressed
;
; @in   up      the label to continue to if UP is currently pressed
; @in   down    the label to jp to if DOWN is currently pressed
; @in   else    the label to jp to if neither UP nor DOWN are currently pressed
;====
.macro "input.ifYDir" args up down else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label up "input.asm \.: Invalid 'up' argument"
    utils.assert.label down "input.asm \.: Invalid 'down' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ld a, (input.ram.activePort.current)
    bit input.DOWN_BIT, a   ; check DOWN bit
    jp nz, down             ; jp to 'down' label if DOWN is pressed

    bit input.UP_BIT, a     ; check UP bit
    jp z, else              ; jp to 'else' label if UP is not pressed

    ; ...continue to 'up' label
.endm

;====
; Detects if either up or down have been pressed for this frame and the
; previous frame, and jumps to the relevant label if one has.
;
; @in   up      the label to continue to if UP is held
; @in   down    the label to jp to if DOWN is held
; @in   else    the label to jp to if neither UP nor DOWN are held
;====
.macro "input.ifYDirHeld" args up down else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label up "input.asm \.: Invalid 'up' argument"
    utils.assert.label down "input.asm \.: Invalid 'down' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    input.loadAHeld         ; load A with held buttons

    ; Check if DOWN is held
    bit input.DOWN_BIT, a   ; check DOWN bit
    jp nz, down             ; jump to 'down' label if down is held

    ; Check if UP is held
    bit input.UP_BIT, a     ; check UP bit
    jp z, else              ; jump to 'else' label if UP is not held

    ; otherwise UP was held, so continue to up label
.endm

;====
; Detects if either up or down have just been pressed this frame, i.e. the
; button was released last frame but is now pressed. Jumps to the relevant
; label if it has.
;
; @in   up      the label to continue to if UP has just been pressed
; @in   down    the label to jp to if DOWN had just been pressed
; @in   else    the label to jp to if neither UP or DOWN have just been pressed
;====
.macro "input.ifYDirPressed" args up down else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label up "input.asm \.: Invalid 'up' argument"
    utils.assert.label down "input.asm \.: Invalid 'down' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load input difference between this frame and last frame
    input.loadADiff

    ; AND with current input; Set bits have changed AND are currently pressed
    and l

    ; Detect whether UP or DOWN have just been pressed (A = --21RLDU)
    bit input.DOWN_BIT, a   ; check DOWN bit
    jp nz, down             ; jump to 'down' label if DOWN is pressed

    ; Check if UP has just been pressed
    bit input.UP_BIT, a     ; check UP bit
    jp z, else              ; jump to 'else' label if UP is not pressed

    ; otherwise UP was pressed, so continue to up label
.endm

;====
; Load the X direction (left/right) into register A. By default, -1 = left,
; 1 = right, 0 = none. The result is multiplied by the optional multiplier
; at assemble time
;
; Ensure you have called input.readPort1 or input.readPort2
;
; @in   [multiplier]    optional multiplier for the result (default 1)
; @out  a               -1 = left, 1 = right, 0 = none. This value will be
;                       multiplied by the multiplier at assemble time
;====
.macro "input.loadADirX" isolated args multiplier
    .ifndef multiplier
        .redefine multiplier 1
    .endif

    ; Read current input data
    ld a, (input.ram.activePort.current)

    ; Check if left is being pressed
    bit input.LEFT_BIT, a
    jp z, +
        ; Left is pressed
        ld a, -1 * multiplier
        jp \.\@end
    +:

    ; Check if right is being pressed
    bit input.RIGHT_BIT, a
    jp z, +
        ; Right is pressed
        ld a, 1 * multiplier
        jp \.\@end
    +:

    ; Nothing pressed
    xor a   ; a = 0

    \.\@end:
.endm

;====
; Load the Y direction (up/down) into register A. By default, -1 = up,
; 1 = down, 0 = none. The result is multiplied by the optional multiplier
; at assemble time
;
; Ensure you have called input.readPort1 or input.readPort2
;
; @in   [multiplier]    optional multiplier for the result (default 1)
; @out  a               -1 = up, 1 = down, 0 = none. This will be multiplied
;                       by the multiplier at assemble time
;====
.macro "input.loadADirY" isolated args multiplier
    .ifndef multiplier
        .redefine multiplier 1
    .endif

    ; Read current input data
    ld a, (input.ram.activePort.current)

    ; Check if up is being pressed
    bit input.UP_BIT, a
    jp z, +
        ; Up is pressed
        ld a, -1 * multiplier
        jp \.\@end
    +:

    ; Check if down is being pressed
    bit input.DOWN_BIT, a
    jp z, +
        ; Down is pressed
        ld a, 1 * multiplier
        jp \.\@end
    +:

    ; Nothing pressed
    xor a   ; a = 0

    \.\@end:
.endm
