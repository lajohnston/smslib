describe "tilemap.stopLeftColScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.stopLeftColScroll
        utils.registers.restore

        expect.all.toBeUnclobbered
