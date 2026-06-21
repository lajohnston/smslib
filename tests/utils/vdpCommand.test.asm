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

describe "utils.vdpCommand.setRegister"
    test "does not clobber registers when a constant is given"
        zest.initRegisters

        utils.preserve
            utils.vdpCommand.setRegister 8, 0
        utils.restore

        expect.all.toBeUnclobbered

    test "does not clobber registers when no constant value given"
        zest.initRegisters
        ld a, 100

        utils.preserve
            utils.vdpCommand.setRegister 8
        utils.restore

        expect.all.toBeUnclobberedExcept "af"
        expect.a.toBe 100

describe "setFromHl"
    test "does not clobber registers (when no operation given)"
        zest.initRegisters

        ld hl, $ffff

        utils.preserve
            utils.vdpCommand.setFromHl
        utils.restore

        expect.all.toBeUnclobberedExcept "hl"
        expect.hl.toBe $ffff

    test "does not clobber registers (when operation given)"
        zest.initRegisters

        utils.preserve
            utils.vdpCommand.setFromHl utils.vdpCommand.READ_VRAM
            utils.vdpCommand.setFromHl utils.vdpCommand.WRITE_VRAM
            utils.vdpCommand.setFromHl utils.vdpCommand.WRITE_CRAM
            utils.vdpCommand.setFromHl utils.vdpCommand.WRITE_REGISTER
        utils.restore

        expect.all.toBeUnclobbered

describe "setFromDe"
    test "does not clobber registers (when no operation given)"
        zest.initRegisters

        ld hl, $ffff

        utils.preserve
            utils.vdpCommand.setFromDe
        utils.restore

        expect.all.toBeUnclobberedExcept "hl"
        expect.hl.toBe $ffff

    test "does not clobber registers (when operation given)"
        zest.initRegisters

        utils.preserve
            utils.vdpCommand.setFromDe utils.vdpCommand.READ_VRAM
            utils.vdpCommand.setFromDe utils.vdpCommand.WRITE_VRAM
            utils.vdpCommand.setFromDe utils.vdpCommand.WRITE_CRAM
            utils.vdpCommand.setFromDe utils.vdpCommand.WRITE_REGISTER
        utils.restore

        expect.all.toBeUnclobbered