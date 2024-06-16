describe "tilemap.writeBytes"
    jr +
        _writeBytesData:
            .db 0
            .dw 1
    +:

    test "does not clobber registers"
        zest.initRegisters

        utils.registers.preserve
            tilemap.setColRow 0 0
            tilemap.writeBytes _writeBytesData 2 0
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "c"
        expect.c.toBe $be
