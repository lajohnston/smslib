describe "i-register preservation"
    test "preserves and restores AF and I"
        ; Set I
        ld a, $10
        ld i, a

        ; Set A
        ld a, $a0
        scf ; set carry

        registers.preserve "AF" "I"
            registers.clobbers "I"
                ; Set I
                push af ; manually preserve A
                    ld a, $11
                    ld i, a
                pop af
            registers.clobberEnd

            registers.clobbers "AF"
                ; Set A
                ld a, $a1
                ccf ; clear carry
            registers.clobberEnd
        registers.restore

        expect.a.toBe $a0
        expect.carry.toBe 1
        expect.i.toBe $10

    test "should preserve multiple nested values"
        ; Set I to 0
        ld a, 0
        ld i, a

        ; Create multiple nested preserve and clobber scopes that inc I
        .repeat registers.I_STACK_MAX_SIZE index index
            registers.preserve "I"
                registers.clobbers "I"
                    inc a
                    ld i, a
        .endr

        ; Restore each nested preserve scope
        .repeat registers.I_STACK_MAX_SIZE index restoreIndex
            registers.clobberEnd
            registers.restore

            expect.i.toBe registers.I_STACK_MAX_SIZE - restoreIndex - 1
        .endr
