describe "sprites.addGroup"
    sprites.init

    jr +
        testSpriteGroup:
            sprites.startGroup
                sprites.sprite 1, 0, 0
                sprites.sprite 2, 8, 0
            sprites.endGroup
    +:

    test "should not clobber any registers"
        sprites.reset

        zest.initRegisters

        registers.preserve
            ld hl, testSpriteGroup
            sprites.addGroup
        registers.restore

        expect.all.toBeUnclobberedExcept "hl"
        expect.hl.toBe testSpriteGroup

    test "when in a batch should not clobber any registers apart from DE"
        zest.initRegisters

        registers.preserve
            sprites.startBatch
                ld hl, testSpriteGroup
                sprites.addGroup
            sprites.endBatch
        registers.restore

        expect.all.toBeUnclobberedExcept "hl" "de"
        expect.hl.toBe testSpriteGroup
