describe "tilemap.calculateScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.calculateScroll
        utils.restore

        expect.all.toBeUnclobbered
