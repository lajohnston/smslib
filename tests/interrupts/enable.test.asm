describe "interrupts.enable"
    test "does not clobber any registers"
        zest.initRegisters

        utils.preserve
            interrupts.enable
        utils.restore

        expect.all.toBeUnclobbered