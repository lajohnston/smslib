;====
; Copies a given number of bytes from one address to another
;
; @in  fromAddress   the 16-bit address of the first byte to copy data from
; @in  toAddress     the 16-bit address of the first byte to copy data to
; @in  byteCount     the number of bytes to copy. If blank, value in bc is used
;
; @clobs            bc, de, hl
;====
.macro "z80.copyFromTo.inline" args fromAddress toAddress byteCount
    .IFDEF byteCount
        ld bc, byteCount
    .ENDIF

    ld hl, fromAddress
    ld de, toAddress
    ldir
.endm

;====
; Copy the value of a byte in RAM to another byte
;
; @in    sourceAddr  the address holding the byte to copy
; @in    destAddr    the address to copy the value to
;
; @clobs af, hl
;====
.macro "z80.copyByte" args sourceAddr destAddr
    ld hl, sourceAddr
    ld a, (hl)
    ld hl, destAddr
    ld (hl), a
.endm

;====
; Set a byte in RAM to the given value
; @in  value the value to copy. If "a", then the value in register a is used
;
; @clobs    af, hl
;====
.macro "z80.setByte" args address value
    .if value != "a"
        ld a, value
    .endif

    ld hl, address
    ld (hl), a
.endm

;====
; Add the value in register a to the value in de
;
; @in  a      the value to add
; @out de   the result
;
; @clobs a
;====
.macro "z80.addAToDe.inline"
    add a, e    ; add e to a
    ld e, a     ; store result back to e
    adc a, d
    sub e
    ld d, a     ; store result in d
.endm

.section "z80.addAToDe" free
    z80.addAToDe:
        z80.addAToDe.inline
        ret
.ends

;====
; Add the value in register a to the value in hl
;
; @in  a      the value to add
; @out hl   the result
;
; @clobs a
;====
.macro "z80.addAToHl.inline"
    add a, l    ; add l to a
    ld l, a     ; store result back to l
    adc a, h
    sub l
    ld h, a     ; store result in h
.endm

.section "z80.addAToHl" free
    z80.addAToHl:
        z80.addAToHl.inline
        ret
.ends

;====
; Add the value in register a to the value in ix
;
; @in  a      the value to add
; @out ix   the result
;
; @clobs a
;====
.macro "z80.addAToIx.inline"
    add a, ixl  ; add ixl to a
    ld ixl, a   ; store result back to ixl
    adc a, ixh
    sub ixl
    ld ixh, a     ; store result in ixh
.endm

.section "z80.addAToIx" free
    z80.addAToIx:
        z80.addAToIx.inline
        ret
.ends

;====
; HL = H*E
;
; @in     h   multiplicand
; @in     e   multiplier
; @out  hl  result
;
; @clobs b, d
;====
.section "z80.multiplyHByE" free
    z80.multiplyHByE:
        ld d, 0                 ; clear d and l
        ld l, d
        ld b, 8                 ; we have 8 bits
        _Mul8bLoop:
            add hl, hl          ; advance a bit
            jp nc, _Mul8bSkip   ; if zero, skip the addition (jp is used for speed)
            add hl, de          ; add to the product if necessary
        _Mul8bSkip:
            djnz _Mul8bLoop
        ret
.ends

;====
; IX = HL + A
;
; @in     hl  the 16-bit value
; @in     a   the 8-bit vale to add
; @out  ix   the result
;
; @clobs af, e
.macro "z80.sumAHlToIx.inline"
    add a, l
    ld ixl, a
    ld e, a     ; temp
    adc a, h
    sub e
    ld ixh, a
.endm

;====
; IY = HL + A
;
; @in     hl  the 16-bit value
; @in     a   the 8-bit vale to add
; @out  iy  the result
;
; @clobs af, e
.macro "z80.sumAHlToIy.inline"
    add a, l
    ld iyl, a
    ld e, a     ; temp
    adc a, h
    sub e
    ld iyh, a
.endm

;====
; DE = IX + A
;
; @in     ix  the 16-bit value
; @in     a   the 8-bit vale to add
; @out  de  the result
;
; @clobs af
.macro "z80.sumAIxToDe.inline"
    add a, ixl
    ld e, a
    adc a, ixh
    sub e
    ld d, a
.endm
