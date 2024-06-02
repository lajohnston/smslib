describe "tilemap.writeRows"
    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            tilemap.setColRow 0, 0
            ld d, 1
            ld e, 2
            ld hl, 0
            tilemap.writeRows
        registers.restore

        expect.all.toBeUnclobberedExcept "c" "de", "hl"
        expect.c.toBe $be   ; vdp data port
        expect.d.toBe 1
        expect.e.toBe 2
        expect.hl.toBe 0
