describe "interrupts.setLineInterval"
    test "does not clobber any registers"
        zest.initRegisters

        utils.preserve
            interrupts.setLineInterval
        utils.restore

        expect.all.toBeUnclobbered