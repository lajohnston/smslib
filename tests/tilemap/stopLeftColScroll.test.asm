describe "tilemap.stopLeftColScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.stopLeftColScroll
        utils.restore

        expect.all.toBeUnclobbered
