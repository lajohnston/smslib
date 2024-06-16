describe "sprites.add"
    sprites.init

    test "should not clobber any registers"
        zest.initRegisters

        utils.registers.preserve
            sprites.add
        utils.registers.restore

        expect.all.toBeUnclobbered

    test "when in a batch should not clobber any registers apart from DE"
        zest.initRegisters

        utils.registers.preserve
            sprites.startBatch
                sprites.add
            sprites.endBatch
        utils.registers.restore

        expect.all.toBeUnclobberedExcept "de"
