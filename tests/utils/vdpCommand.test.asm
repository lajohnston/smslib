describe "utils.vdpCommand.setVramWriteAddress"
    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            utils.vdpCommand.setVramWriteAddress 0
        utils.restore

        expect.all.toBeUnclobbered

describe "utils.vdpCommand.setColorRamWriteAddress"
    test "does not clobber registers"
        zest.initRegisters

        utils.preserve
            utils.vdpCommand.setColorRamWriteAddress 31
        utils.restore

        expect.all.toBeUnclobbered