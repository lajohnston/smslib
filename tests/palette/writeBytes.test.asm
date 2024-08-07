describe "palette.writeBytes"
    jr +
        _palette.writeBytes.data:
            .db 0
            .db 1
            .db 3
    +:

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            palette.setIndex 0
            palette.writeBytes _palette.writeBytes.data 1
        utils.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port
