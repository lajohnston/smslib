describe "tilemap.reset"
    test "does not clobber registers"
        zest.initRegisters

        utils.registers.preserve
            tilemap.reset
        utils.registers.restore

        expect.all.toBeUnclobbered
