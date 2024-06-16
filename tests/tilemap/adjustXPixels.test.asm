describe "tilemap.adjustXPixels"
    tilemap.reset

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            ld a, 1
            tilemap.adjustXPixels
        utils.restore

        expect.all.toBeUnclobberedExcept "a"
        expect.a.toBe 1
