describe "tilemap.setIndex"
    test "sets C to the VDP data port but does not clobber other registers"
        zest.initRegisters

        utils.preserve
            tilemap.setIndex 1
        utils.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port

    test "allows the index to be set from 0 to 895"
        tilemap.setIndex 0
        tilemap.setIndex 895