describe "palette.writeRgb"
    test "does not clobber the registers"
        zest.initRegisters

        utils.preserve
            palette.setIndex 0
            palette.writeRgb 100 150 200
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be   ; vdp data port
