describe "interrupts.waitForVBlank"
    test "does not clobber any registers"
        ; Set VBlank flag
        ld a, 1
        ld (interrupts.ram.vBlankFlag), a

        zest.initRegisters

        utils.preserve
            interrupts.waitForVBlank
        utils.restore

        expect.all.toBeUnclobbered