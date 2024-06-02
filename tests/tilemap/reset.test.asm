describe "tilemap.reset"
    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            tilemap.reset
        registers.restore

        expect.all.toBeUnclobbered
