;===
; Input
;
; Reads and interprets joypad inputs
;====

.define input.ENABLED 1

; Dependencies
.include "./utils/ramSlot.asm"

; Constants
.define input.UP        0
.define input.DOWN      1
.define input.LEFT      2
.define input.RIGHT     3
.define input.BUTTON_1  4
.define input.BUTTON_2  5

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
; Checks whether a button is currently being held down
;
; @in  button   the button to check, either input.UP, input.DOWN, input.LEFT,
;               input.RIGHT, input.BUTTON_1 or input.BUTTON_2
;
; @out  f       nz if the given button is pressed
.macro "input.isHeld" args button
    ld a, (input.ram.activePort.current)
    bit button, a
.endm

;===
; Check if a given button has been pressed
;
; @in   button  the button to check (input.UP, input.BUTTON_1 etc)
; @in   else    the address to jump to if the button is not pressed
;===
.macro "input.if" args button else
    input.isHeld button
    jp z, else
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
    bit input.LEFT, a
    jp z, +
        ; Left is pressed
        ld a, -1 * multiplier
        jp \.\@end
    +:

    ; Check if right is being pressed
    bit input.RIGHT, a
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
    bit input.UP, a
    jp z, +
        ; Up is pressed
        ld a, -1 * multiplier
        jp \.\@end
    +:

    ; Check if down is being pressed
    bit input.DOWN, a
    jp z, +
        ; Down is pressed
        ld a, 1 * multiplier
        jp \.\@end
    +:

    ; Nothing pressed
    xor a   ; a = 0

    \.\@end:
.endm