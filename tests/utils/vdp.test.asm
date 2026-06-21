describe "utils.vdp.setRegister"
    test "does not clobber registers when constant given"
        zest.initRegisters

        utils.preserve
            utils.vdp.setRegister utils.vdp.LINE_COUNTER_REGISTER, 0
        utils.restore

        expect.all.toBeUnclobbered

    test "does not clobber registers when no constant value given"
        zest.initRegisters
        ld a, 100

        utils.preserve
            utils.vdp.setRegister utils.vdp.LINE_COUNTER_REGISTER
        utils.restore

        expect.all.toBeUnclobberedExcept "af"
        expect.a.toBe 100
