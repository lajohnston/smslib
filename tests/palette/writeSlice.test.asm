describe "palette.writeSlice"
    jr +
        _palette.writeSlice.data:
            .db 0
            .db 1
            .db 3
    +:

    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            palette.writeSlice _palette.writeSlice.data 1
        registers.restore

        expect.all.toBeUnclobbered

describe "palette.writeSlice with offset"
    test "does not clobber registers"
        zest.initRegisters

        registers.preserve
            palette.writeSlice _palette.writeSlice.data 1 1
        registers.restore

        expect.all.toBeUnclobbered
