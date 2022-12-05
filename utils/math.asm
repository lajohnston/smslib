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
; IY = IY + A (unsigned)
;
; @in  a    value to add to IY
; @in  iy   value to add A to
; @out iy   result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#add-unsigned
;====
.macro "utils.math.addIYA"
    add a, iyl  ; A = A+IYL
    ld iyl, a   ; IYL = A+IYL
    adc a, iyh  ; A = A+IYL+IYH+carry
    sub iyl     ; A = IYL+carry
    ld iyh, a   ; IYH = IYH+carry
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
; IX = IX - A (unsigned)
;
; @in  a    value to subtract from IX
; @in  ix   value from which to subtract
; @out ix   result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#sub-unsigned
;====
.macro "utils.math.subIXA" isolated
    neg                     ; negate a
    jp z, +                 ; skip if A is zero
        dec ixh             ; pretend 'high byte' is -1, so sub 1 from high byte
        utils.math.addIXA   ; add as normal
    +:
.endm

;====
; IX = IX - value (unsigned)
;
; @in  value    value to subtract from IX
; @in  ix       value from which to subtract
; @out ix       result
;
; @source https://www.plutiedev.com/z80-add-8bit-to-16bit#sub-unsigned
;====
.macro "utils.math.subIX" isolated args value
    .if value != 0
        ld a, -value        ; load A with the negated value
        dec ixh             ; pretend 'high byte' is -1, so sub 1 from high byte
        utils.math.addIXA   ; add as normal
    .endif
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

;====
; Multiply HL by a given constant. Only certain numbers are currently supported.
; It's more efficient to keep multipliers to: 2, 4, 8, 16, 32, 64. Other
; multipliers are less efficient and will clobber BC and maybe DE
;
; @in   hl          the value to multiply
; @in   multiplier  the constant to multiply by
; @out  hl          the result
;
; @source http://www.cpctech.cpc-live.com/docs/mult.html
;====
.macro "utils.math.multiplyHL" args multiplier
    .if ceil(multiplier) != multiplier
        .print "utils.math.multiplyHL: Ensure multiplier is a whole number\n"
        .fail
    .endif

    .if multiplier == 0
        ld hl, 0
    .elif multiplier == 1
        ; do nothing
    .elif multiplier == 2
        add hl, hl  ; x2
    .elif multiplier == 3
        ld b, h     ; preserve HLx1 in BC
        ld c, l     ; "
        add hl, hl  ; x2
        add hl, bc  ; add x1 to get x3
    .elif multiplier == 4
        add hl, hl  ; x2
        add hl, hl  ; x4
    .elif multiplier == 5
        ld b, h     ; preserve HL in BC
        ld c, l     ; "
        add hl, hl  ; x2
        add hl, hl  ; x4
        add hl, bc  ; add HLx1 to get x5
    .elif multiplier == 6
        add hl, hl  ; x2
        ld b, h     ; preserve HLx2 in BC
        ld c, l     ; "
        add hl, hl  ; x4
        add hl, bc  ; add x2 to get x6
    .elif multiplier == 7
        ld b, h     ; preserve HLx1 in BC
        ld c, l     ; "
        add hl, hl  ; x2
        add hl, hl  ; x4
        add hl, bc  ; add x1 to get x5
        add hl, bc  ; add x1 to get x6
        add hl, bc  ; add x1 to get x7
    .elif multiplier == 8
        add hl, hl  ; x2
        add hl, hl  ; x4
        add hl, hl  ; x8
    .elif multiplier == 12
        add hl, hl  ; x2
        add hl, hl  ; x4
        ld b, h     ; preserve HLx4 in BC
        ld c, l     ; "
        add hl, hl  ; x8
        add hl, bc  ; add x4 to get x12
    .elif multiplier == 16
        add hl, hl  ; x2
        add hl, hl  ; x4
        add hl, hl  ; x8
        add hl, hl  ; x16
    .elif multiplier == 24
        add hl, hl  ; x2
        add hl, hl  ; x4
        add hl, hl  ; x8
        ld b, h     ; preserve HLx8 in BC
        ld c, l     ; "
        add hl, hl  ; x16
        add hl, bc  ; add x8 to get x24
    .elif multiplier == 25
        ld b, h     ; preserve HLx1 in BC
        ld c, l     ; "
        add hl, hl  ; x2
        add hl, hl  ; x4
        add hl, hl  ; x8
        ld d, h     ; preserve HLx8 in DE
        ld e, l     ; "
        add hl, hl  ; x16
        add hl, de  ; add x8 to get x24
        add hl, bc  ; add x1 to get x25
    .elif multiplier == 32
        add hl, hl  ; x2
        add hl, hl  ; x4
        add hl, hl  ; x8
        add hl, hl  ; x16
        add hl, hl  ; x32
    .elif multiplier == 64
        add hl, hl  ; x2
        add hl, hl  ; x4
        add hl, hl  ; x8
        add hl, hl  ; x16
        add hl, hl  ; x32
        add hl, hl  ; x64
    .else
        .print "utils.math.multiplyHL does not currently support multiplying by ", dec multiplier, "\n"
        .fail
    .endif
.endm

;====
; Multiply two unsigned bytes together
;
; @in   h   the multiplier
; @in   e   the multiplicand
; @out  hl  the product
;
; @source https://tutorials.eeems.ca/Z80ASM/part4.htm
;====
.macro "utils.math.multiplyHByE"
    call utils.math.multiplyHByE
.endm

;====
; See utils.math.multiplyHByE macro
;====
.section "utils.math.multiplyHByE" free
    utils.math.multiplyHByE:
        ; Zero D and L
        ld d, 0
        ld l, d

        ; Bits in the multiplier
        .repeat 8 index bit
            -:
                add hl, hl      ; advance a bit

                .if bit < 7
                    jp nc, +    ; if bit is 0, skip the addition
                .else
                    ret nc      ; if final bit is 0, return
                .endif

                ; If bit is 1, add to the product
                add hl, de
            +:
        .endr

        ret
.ends
