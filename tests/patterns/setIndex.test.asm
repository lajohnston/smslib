describe "patterns.setIndex"
    test "sets C to the VDP data port but does not clobber other registers"
        zest.initRegisters

        utils.registers.preserve
            patterns.setIndex 1
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port

    test "allows the index to be set from 0 to 511"
        patterns.setIndex 0
        patterns.setIndex 511