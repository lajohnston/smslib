describe "palette.writeSlice"
    jr +
        _palette.writeSlice.data:
            .db 0
            .db 1
            .db 3
    +:

    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            palette.setIndex 0
            palette.writeSlice _palette.writeSlice.data 1
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port

describe "palette.writeSlice with offset"
    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            palette.setIndex 0
            palette.writeSlice _palette.writeSlice.data 1 1
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port
