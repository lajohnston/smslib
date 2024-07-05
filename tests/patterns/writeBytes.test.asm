describe "patterns.writeBytes"
    jr +
        _patterns.writeBytes.data:
            .db 0
            .db 1
            .db 3
    +:

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            patterns.setIndex 0
            patterns.writeBytes _patterns.writeBytes.data 1
        utils.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port
