describe "i-register preservation"
    test "preserves and restores AF and I"
        zest.initRegisters

        registers.preserve "af" "i"
            registers.clobbers "i"
                ld i, a
            registers.clobberEnd

            registers.clobbers "af"
                inc a
            registers.clobberEnd
        registers.restore

        expect.all.toBeUnclobbered

    test "should preserve multiple nested values"
        ; Set I to 0
        ld a, 0
        ld i, a

        ; Create multiple nested preserve and clobber scopes that inc I
        .repeat registers.I_STACK_MAX_SIZE index index
            registers.preserve "i"
                registers.clobbers "i"
                    inc a
                    ld i, a
        .endr

        ; Restore each nested preserve scope
        .repeat registers.I_STACK_MAX_SIZE index restoreIndex
                registers.clobberEnd
            registers.restore

            expect.i.toBe registers.I_STACK_MAX_SIZE - restoreIndex - 1
        .endr
