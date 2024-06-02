describe "tilemap.stopUpRowScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            tilemap.stopUpRowScroll
        registers.restore

        expect.all.toBeUnclobbered
