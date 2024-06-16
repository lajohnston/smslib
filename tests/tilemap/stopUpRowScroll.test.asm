describe "tilemap.stopUpRowScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.registers.preserve
            tilemap.stopUpRowScroll
        utils.registers.restore

        expect.all.toBeUnclobbered
