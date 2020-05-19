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
; Reads controller port 1 input into the given register
;
; @out   a      Reset bits represent the buttons currently pressed
;       xx000000
;       |||||||*- Up
;       ||||||*-- Down
;       |||||*--- Left
;       ||||*---- Right
;       |||*----- Button 1
;       ||*------ Button 2
;       ** junk (actually, port B down and up, respectively)
;====
.macro "input.readPort1"
    in a, input.PORT_1
    input._store
.endm

;====
; Stores the read input value into the given register
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
    in a, input.PORT_1
    and %11000000       ; mask out port A buttons
    ld b, a

    in a, input.PORT_2
    and %00001111       ; mask out misc. buttons
    or b                ; combine both masks

    ; Rotate left twice to match port A format
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
; @param button     the button to check (input.UP, input.BUTTON_1 etc)
; @param else       the address to jump to if the button is not pressed
;===
.macro "input.if" args button else
    input.isPressed button
    jp nz, else
.endm
