describe "tilemap.reset"
    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.reset
        utils.restore

        expect.all.toBeUnclobbered
