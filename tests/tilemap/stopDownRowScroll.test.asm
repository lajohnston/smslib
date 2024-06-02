describe "tilemap.stopDownRowScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            tilemap.stopDownRowScroll
        registers.restore

        expect.all.toBeUnclobbered
