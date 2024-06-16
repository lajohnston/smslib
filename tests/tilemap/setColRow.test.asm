describe "tilemap.setColRow"
    test "sets C to the VDP data port but does not clobber other registers"
        zest.initRegisters

        utils.preserve
            tilemap.setColRow 0 0
        utils.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port

    test "allows the column to be set from 0-31"
        tilemap.setColRow 0 0
        tilemap.setColRow 31 0

    test "allows the row to be set from 0-27"
        tilemap.setColRow 0 0
        tilemap.setColRow 0 27