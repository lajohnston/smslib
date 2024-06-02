describe "tilemap.stopLeftColScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            tilemap.stopLeftColScroll
        registers.restore

        expect.all.toBeUnclobbered
