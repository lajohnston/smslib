describe "pause.init"
    test "does not clobber any registers"
        zest.initRegisters

        utils.preserve
            pause.init
        utils.restore

        expect.all.toBeUnclobbered