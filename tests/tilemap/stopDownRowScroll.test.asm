describe "tilemap.stopDownRowScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.stopDownRowScroll
        utils.restore

        expect.all.toBeUnclobbered
