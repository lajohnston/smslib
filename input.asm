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

; Variables
.ramsection "input.ram" slot utils.ramSlot
    input.ram.activePort.current: db
.ends

;====
; Initialises the input handler in RAM
;====
.macro "input.init"
    xor a
    ld (input.ram.activePort.current), a
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
    in a, input.PORT_1
    ld (input.ram.activePort.current), a
.endm

; Reads the input from controller port 2 into the ram buffer
; See input.readPort1 documentation for details
.macro "input.readPort2"
    ; Retrieve up and down buttons, which are stored within input1 byte
    in a, input.PORT_1
    and %11000000       ; mask out port A buttons
    ld b, a             ; store in b

    in a, input.PORT_2  ; read remaining buttons
    and %00001111       ; mask out misc. buttons
    or b                ; combine both masks

    ; Rotate left twice to match port 1 format
    rlca
    rlca

    ; Store in ram buffer
    ld (input.ram.activePort.current), a
.endm

;====
; Checks whether a button is currently being pressed
;
; @in  button  the button to check, either input.UP, input.DOWN, input.LEFT,
;              input.RIGHT, input.BUTTON_1 or input.BUTTON_2
;
; @out  f       z if the given button is pressed
.macro "input.isPressed" args button
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
    input.isPressed button
    jp nz, else
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
    jp nz, +
        ; Left is pressed
        ld a, -1 * multiplier
        jp \.\@end
    +:

    ; Check if right is being pressed
    bit input.RIGHT, a
    jp nz, +
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
    jp nz, +
        ; Up is pressed
        ld a, -1 * multiplier
        jp \.\@end
    +:

    ; Check if down is being pressed
    bit input.DOWN, a
    jp nz, +
        ; Down is pressed
        ld a, 1 * multiplier
        jp \.\@end
    +:

    ; Nothing pressed
    xor a   ; a = 0

    \.\@end:
.endm