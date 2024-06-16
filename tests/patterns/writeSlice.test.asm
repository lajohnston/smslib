describe "patterns.writeSlice"
    jr +
        _patterns.writeSlice.data:
            .db 0
            .db 1
            .db 3
    +:

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            patterns.setIndex 0
            patterns.writeSlice _patterns.writeSlice.data 1
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port

describe "patterns.writeSlice with offset"
    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            patterns.setIndex 0
            patterns.writeSlice _patterns.writeSlice.data 1 1
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port
