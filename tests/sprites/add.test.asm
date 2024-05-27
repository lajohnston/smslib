describe "sprites.add"
    test "should not clobber any registers"
        zest.initRegisters

        registers.preserve
            sprites.add
        registers.restore

        expect.all.toBeUnclobbered

    test "when in a batch should not clobber any registers apart from DE"
        sprites.startBatch
            zest.initRegisters

            registers.preserve
                sprites.add
            registers.restore

            expect.all.toBeUnclobberedExcept "de"
        sprites.endBatch

        sprites.reset
