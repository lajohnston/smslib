describe "input.readPort2"
    test "preserves registers"
        zest.initRegisters

        utils.preserve
            input.readPort2
        utils.restore

        expect.all.toBeUnclobbered
