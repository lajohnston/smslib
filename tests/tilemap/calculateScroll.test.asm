describe "tilemap.calculateScroll"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.registers.preserve
            tilemap.calculateScroll
        utils.registers.restore

        expect.all.toBeUnclobbered
