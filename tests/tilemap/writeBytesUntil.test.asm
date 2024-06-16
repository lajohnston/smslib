describe "tilemap.writeBytesUntil"
    jr +
        _writeBytesUntilData:
            .db 0
            .dw 1
            .db $ff
    +:

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            tilemap.setColRow 0 0
            tilemap.writeBytesUntil $ff _writeBytesUntilData tilemap.FLIP_XY
        utils.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port
