.section "suite.registers helpers"
    suite.registers.setAllToZero:
        xor a
    suite.registers.setAllToA:
        ld b, a
        ld c, a
        ld d, a
        ld e, a
        ld h, a
        ld l, a
        ld ixl, a
        ld ixh, a
        ld iyl, a
        ld iyh, a
        ld i, a

        push hl
        pop af      ; set flags

        ex af, af'
        ld a, b
        exx
        ld b, a
        ld c, a
        ld d, a
        ld e, a
        ld h, a
        ld l, a

        push hl
        pop af      ; set flags

        ret

    suite.registers.clobberAll:
        ex af, af'  ; switch AF and AF' to clobber both
        exx         ; switch main registers with shadow to clobber both sets

        ; Clobber index registers
        ld ixl, a
        ld ixh, a
        ld iyl, a
        ld iyh, a
        ld i, a
        ret

    suite.registers.expectAllToBeZero:
        expect.a.toBe 0
        expect.bc.toBe 0
        expect.de.toBe 0
        expect.hl.toBe 0
        expect.ix.toBe 0
        expect.iy.toBe 0
        expect.i.toBe 0

        ex af, af'
            expect.a.toBe 0
        ex af, af'
        exx
            expect.bc.toBe 0
            expect.de.toBe 0
            expect.hl.toBe 0
        exx
        ret

    suite.registers.setAllFlags:
        push hl
            ld h, a
            ld l, $ff   ; flags
            push hl     ; push to stack
            pop af      ; restore to AF
        pop hl
        ret

    suite.registers.resetAllFlags:
        push hl
            ld h, a
            ld l, 0     ; flags
            push hl     ; push to stack
            pop af      ; restore to AF
        pop hl
        ret
.ends