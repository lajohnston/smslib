describe "tilemap.writeTile"
    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.setColRow 0, 0
            tilemap.writeTile 1
            tilemap.writeTile 2 tilemap.FLIP_X
        utils.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port

    test "allows the pattern to be 0 to 511"
        tilemap.setColRow 0, 0
        tilemap.writeTile 0
        tilemap.writeTile 511
