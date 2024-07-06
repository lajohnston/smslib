describe "interrupts.init"
    test "does not clobber any registers"
        zest.initRegisters

        utils.preserve
            interrupts.init
        utils.restore

        expect.all.toBeUnclobbered