describe "tilemap.stopRightColScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            tilemap.stopRightColScroll
        registers.restore

        expect.all.toBeUnclobbered
