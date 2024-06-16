describe "tilemap.adjustYPixels"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.registers.preserve
            ld a, 1
            tilemap.adjustYPixels
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "a"
        expect.a.toBe 1
