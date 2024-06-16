describe "palette.setIndex"
    test "sets C to the port but does not clobber other registers"
        zest.initRegisters

        utils.preserve
            palette.setIndex 1
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port

    test "allows the index to be set from 0 to 31"
        palette.setIndex 0
        palette.setIndex 31
