;===
; Input
;
; Reads and interprets joypad inputs
;====

; Constants
.define input.PORT_A $dc
.define input.PORT_B $dd

; Option masks to pass to input comparison functions
.define input.UP        0
.define input.DOWN      1
.define input.LEFT      2
.define input.RIGHT     3
.define input.BUTTON1   4
.define input.BUTTON2   5

;====
; Reads port A input into register a
;
; @out  a   Reset bits represent the buttons currently pressed
;          	    xx000000
;           	|||||||*- Up
;               ||||||*-- Down
;               |||||*--- Left
;               ||||*---- Right
;               |||*----- Button 1
;               ||*------ Button 2
;               ** junk (actually, port B down and up, respectively)
;====
.macro "input.readPortA"
    in a, input.PORT_A
.endm

; See input.readPortA doc
.macro "input.readPortB"
    push bc
        in a, input.PORT_A
        and %11000000       ; mask out port A buttons
        ld b, a

        in a, input.PORT_B
        and %00001111       ; mask out misc. buttons
        or b                ; combine both masks

        ; Rotate left twice to match port A format
        rlca
        rlca
    pop bc
.endm

;====
; Checks whether a button is currently being pressed
;
; @in  a      the current input
; @in  check  the button to check, either input.UP, input.DOWN, input.LEFT,
;             input.RIGHT, input.BUTTON1 or input.BUTTON2
;
; @out  f   z if the given button is pressed
.macro "input.check" args check
    bit check, a
.endm
