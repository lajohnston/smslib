describe "tilemap.stopDownRowScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.registers.preserve
            tilemap.stopDownRowScroll
        utils.registers.restore

        expect.all.toBeUnclobbered
