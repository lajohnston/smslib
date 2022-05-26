;====
; Z80 math routines
;====
.define utils.math 1

;====
; hl = hl + a (unsigned)
;
; @in  a    value to add to HL
; @in  hl   value to add A to
; @out hl   result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#add-unsigned
;====
.macro "utils.math.addHLA"
    add a, l  ; A = A+L
    ld l, a   ; L = A+L
    adc a, h  ; A = A+L+H+carry
    sub l     ; A = H+carry
    ld h, a   ; H = H+carry
.endm

;====
; DE = DE + A (unsigned)
;
; @in  a    value to add to DE
; @in  de   value to add A to
; @out de   result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#add-unsigned
;====
.macro "utils.math.addDEA"
    add a, e  ; A = A+E
    ld e, a   ; E = A+E
    adc a, d  ; A = A+E+D+carry
    sub e     ; A = D+carry
    ld d, a   ; D = D+carry
.endm

;====
; BC = BC + A (unsigned)
;
; @in  a    value to add to BC
; @in  bc   value to add A to
; @out bc   result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#add-unsigned
;====
.macro "utils.math.addBCA"
    add a, c  ; A = A+C
    ld c, a   ; C = A+C
    adc a, b  ; A = A+C+B+carry
    sub c     ; A = B+carry
    ld b, a   ; B = B+carry
.endm

;====
; IX = IX + A (unsigned)
;
; @in  a    value to add to IX
; @in  ix   value to add A to
; @out ix   result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#add-unsigned
;====
.macro "utils.math.addIXA"
    add a, ixl  ; A = A+IXL
    ld ixl, a   ; IXL = A+IXL
    adc a, ixh  ; A = A+IXL+IXH+carry
    sub ixl     ; A = IXH+carry
    ld ixh, a   ; IXH = IXH+carry
.endm

;====
; Left shift HL
;
; @source https://chilliant.com/z80shift.html
;
; @in   hl  the value to left shift
; @in   x   the number of times to shift left (default = 1)
;====
.macro "utils.math.leftShiftHL" args x
    .ifndef x
        .define x 1
    .endif

    .ifleeq x 5
        .repeat x
            add hl, hl
        .endr
    .endif

    .ifeq x 6
        xor a
        srl h
        rr l
        rra
        srl h
        rr l
        rra
        ld h, l
        ld l, a
    .endif

    .ifeq x 7
        xor a
        srl h
        rr l
        rra
        ld h, l
        ld l, a
    .endif

    .ifeq x 8
        ld h, l
        ld l, 0
    .endif

    .ifeq x 9
        sla l
        ld h, l
        ld l, 0
    .endif

    .ifgr x 9
        .print "\nutils.math.leftShiftHL can't currently shift by more than 9"
        .fail
    .endif
.endm

;====
; Right shift HL
;
; @source https://chilliant.com/z80shift.html
;
; @in   hl  the value to right shift
; @in   x   the number of times to shift right (default = 1)
;====
.macro "utils.math.rightShiftHL" args x
    .ifndef x
        .define x 1
    .endif

    .ifleeq x 2
        .repeat x
            srl h
            rr l
        .endr
    .endif

    .ifeq x 3
        ld a, l
        srl h
        rra
        srl h
        rra
        srl h
        rra
        ld l, a
    .endif

    .ifeq x 4
        ld a, l
        srl h
        rra
        srl h
        rra
        srl h
        rra
        srl h
        rra
        ld l, a
    .endif

    .ifgr x 4
        .print "\nutils.math.rightShiftHL can't currently shift by more than 9"
        .fail
    .endif
.endm

;====
; Right shift DE
;
; @source https://chilliant.com/z80shift.html
;
; @in   de  the value to right shift
; @in   x   the number of times to shift right (default = 1)
;====
.macro "utils.math.rightShiftDE" args x
    .ifndef x
        .define x 1
    .endif

    .ifleeq x 2
        .repeat x
            srl d
            rr e
        .endr
    .endif

    .ifeq x 3
        ld a, e
        srl d
        rra
        srl d
        rra
        srl d
        rra
        ld e, a
    .endif

    .ifeq x 4
        ld a, e
        srl d
        rra
        srl d
        rra
        srl d
        rra
        srl d
        rra
        ld e, a
    .endif

    .ifgr x 4
        .print "\nutils.math.rightShiftDE can't currently shift by more than 9"
        .fail
    .endif
.endm

;====
; Divide HL by a constant
;
; @in   hl  the number to divide
; @out  hl  the result
;====
.macro "utils.math.divHLX" args x
    utils.math.shiftHLLeft x
.endm

;====
; hl = hl - a (unsigned)
;
; @in  a    value to subtract from HL
; @in  hl   value from which to subtract
; @out hl   result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#sub-unsigned
;====
.macro "utils.math.subHLA" isolated
    neg                     ; negate a
    jp z, +                 ; skip if A is zero
        dec h               ; pretend 'high byte' is -1, so sub 1 from high byte
        utils.math.addHLA   ; add as normal
    +:
.endm

;====
; DE = DE - A (unsigned)
;
; @in  a    value to subtract from DE
; @in  de   value from which to subtract
; @out de   result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#sub-unsigned
;====
.macro "utils.math.subDEA" isolated
    neg                     ; negate a
    jp z, +                 ; skip if A is zero
        dec d               ; pretend 'high byte' is -1, so sub 1 from high byte
        utils.math.addDEA   ; add as normal
    +:
.endm

;====
; Add a signed value to HL
;
; @in   a   signed value to add to HL
; @in   hl  value to add A to
; @out  hl  result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#add-signed
;====
.macro "utils.math.addSignedHLA"
    or a        ; evaluate A
    jp p, +     ; jp if A is not signed
        ; A is signed
        dec h   ; sub 256 from HL to simulate A having an $FF upper byte
    +:

    utils.math.addHLA   ; normal addition to handle lower byte
.endm