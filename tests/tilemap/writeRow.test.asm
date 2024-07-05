describe "tilemap.writeRow"
    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.setColRow 0, 0
            ld hl, 0
            tilemap.writeRow
        utils.restore

        expect.all.toBeUnclobberedExcept "c" "hl"
        expect.c.toBe $be   ; vdp data port
        expect.hl.toBe 0
