describe "tilemap.loadHLWriteAddress"
    test "returns HL but doesn't clobber other registers"
        zest.initRegisters

        utils.preserve
            tilemap.loadHLWriteAddress
        utils.restore

        expect.all.toBeUnclobberedExcept "hl"

    test "sets the high bits to %01 for the VDP write command"
        ld hl, 12 + (27 * 32) ; col 12, row 27
        tilemap.loadHLWriteAddress
        ld a, h
        and %11000000
        expect.a.toBe %01000000
