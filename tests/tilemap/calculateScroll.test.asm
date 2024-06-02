describe "tilemap.calculateScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            tilemap.calculateScroll
        registers.restore

        expect.all.toBeUnclobbered
