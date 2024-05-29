describe "palette.writeRgb"
    test "does not clobber the registers"
        zest.initRegisters

        registers.preserve
            palette.setIndex 0
            palette.writeRgb 100 150 200
        registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port
