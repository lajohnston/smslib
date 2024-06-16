describe "tilemap.stopUpRowScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.stopUpRowScroll
        utils.registers.restore

        expect.all.toBeUnclobbered
