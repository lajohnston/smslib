describe "sprites.copyToVram"
    sprites.init

    test "should not clobber any registers when there are no sprites"
        sprites.reset
        zest.initRegisters

        utils.preserve
            sprites.copyToVram
        utils.registers.restore

        expect.all.toBeUnclobbered

    test "should not clobber any registers when there are sprites"
        sprites.reset
        sprites.add

        zest.initRegisters

        utils.preserve
            sprites.copyToVram
        utils.registers.restore

        expect.all.toBeUnclobbered
