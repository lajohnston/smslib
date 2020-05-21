;===
; Input
;
; Reads and interprets joypad inputs
;====

; Constants
.define input.UP        0
.define input.DOWN      1
.define input.LEFT      2
.define input.RIGHT     3
.define input.BUTTON1   4
.define input.BUTTON2   5
.define input.PORT_1    $dc
.define input.PORT_2    $dd

; Variables

; The register to store the input data once parsed
.define input.register "b"

;====
; Set the register used to hold the input value for processing
; The default is register b
;
; @in register  the register ("a", "b", "c", "d", "e", "h", "l")
;====
.macro "input.setRegister" args register
    .redefine input.register register
.endm

;====
; Reads the input from controller port 1 into the register specified by
; input.setRegister
;
; @out  (a|b|c|d|e|h|l) -   depending on register given to input.setRegister
;                           (default b)
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
    input._store
.endm

;====
; Stores the read input value into the register given to input.setRegister
; (default is b)
;====
.macro "input._store"
    .if input.register == "b"
        ld b, a
    .endif

    .if input.register == "c"
        ld c, a
    .endif

    .if input.register == "d"
        ld d, a
    .endif

    .if input.register == "e"
        ld e, a
    .endif

    .if input.register == "h"
        ld h, a
    .endif

    .if input.register == "l"
        ld l, a
    .endif
.endm

; See input.readPort1 doc
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

    input._store
.endm

;====
; Checks whether a button is currently being pressed
;
; @in  a       the current input
; @in  button  the button to check, either input.UP, input.DOWN, input.LEFT,
;              input.RIGHT, input.BUTTON1 or input.BUTTON2
;
; @out  f   z if the given button is pressed
.macro "input.isPressed" args button
    .if input.register == "a"
        bit button, a
    .endif

    .if input.register == "b"
        bit button, b
    .endif

    .if input.register == "c"
        bit button, c
    .endif

    .if input.register == "d"
        bit button, d
    .endif

    .if input.register == "e"
        bit button, e
    .endif

    .if input.register == "h"
        bit button, h
    .endif

    .if input.register == "l"
        bit button, l
    .endif
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
