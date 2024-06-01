describe "sprites.add"
    sprites.init

    test "should not clobber any registers"
        zest.initRegisters

        registers.preserve
            sprites.add
        registers.restore

        expect.all.toBeUnclobbered

    test "when in a batch should not clobber any registers apart from DE"
        zest.initRegisters

        registers.preserve
            sprites.startBatch
                sprites.add
            sprites.endBatch
        registers.restore

        expect.all.toBeUnclobberedExcept "de"
