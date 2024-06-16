describe "i-register preservation"
    test "preserves and restores AF and I"
        zest.initRegisters

        utils.preserve "af" "i"
            utils.registers.clobbers "i"
                ld i, a
            utils.registers.clobberEnd

            utils.registers.clobbers "af"
                inc a
            utils.registers.clobberEnd
        utils.restore

        expect.all.toBeUnclobbered

    test "should preserve multiple nested values"
        ; Set I to 0
        ld a, 0
        ld i, a

        ; Create multiple nested preserve and clobber scopes that inc I
        .repeat utils.registers.I_STACK_MAX_SIZE index index
            utils.preserve "i"
                utils.registers.clobbers "i"
                    inc a
                    ld i, a
        .endr

        ; Restore each nested preserve scope
        .repeat utils.registers.I_STACK_MAX_SIZE index restoreIndex
                utils.registers.clobberEnd
            utils.restore

            expect.i.toBe utils.registers.I_STACK_MAX_SIZE - restoreIndex - 1
        .endr
