describe "tilemap.stopRightColScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.registers.preserve
            tilemap.stopRightColScroll
        utils.registers.restore

        expect.all.toBeUnclobbered
