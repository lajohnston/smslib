describe "tilemap.writeTiles"
    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.setColRow 0, 0
            ld hl, 0
            tilemap.writeTiles 2
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c", "hl"
        expect.hl.toBe 0
        expect.c.toBe $be   ; vdp data port
