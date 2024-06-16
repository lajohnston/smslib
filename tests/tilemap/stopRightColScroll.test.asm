describe "tilemap.stopRightColScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.stopRightColScroll
        utils.registers.restore

        expect.all.toBeUnclobbered
