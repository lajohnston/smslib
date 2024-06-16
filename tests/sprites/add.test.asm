describe "sprites.add"
    sprites.init

    test "should not clobber any registers"
        zest.initRegisters

        utils.preserve
            sprites.add
        utils.restore

        expect.all.toBeUnclobbered

    test "when in a batch should not clobber any registers apart from DE"
        zest.initRegisters

        utils.preserve
            sprites.startBatch
                sprites.add
            sprites.endBatch
        utils.restore

        expect.all.toBeUnclobberedExcept "de"
