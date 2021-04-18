;===
; Input
;
; Reads and interprets joypad inputs
;====

.define input.ENABLED 1

; Dependencies
.include "./utils/ram.asm"

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
.ramsection "input.ram" slot utils.ram.SLOT
    input.ram.value: db
.ends

;====
; Initialises the input handler in RAM
;====
.macro "input.init"
    xor a
    ld de, input.ram.value
    ld (de), a
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
    ld (input.ram.value), a
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
    ld (input.ram.value), a
.endm

;====
; Checks whether a button is currently being pressed
;
; @in  a       the current input
; @in  button  the button to check, either input.UP, input.DOWN, input.LEFT,
;              input.RIGHT, input.BUTTON_1 or input.BUTTON_2
;
; @out  f       z if the given button is pressed
.macro "input.isPressed" args button
    ld a, (input.ram.value)
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
