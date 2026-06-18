describe "interrupts.waitForVBlank"
    test "does not clobber any registers"
        zest.mockVdpStatusFlags zest.VDP_NO_STATUS_FLAGS

        ; Will set VBlank flag at next VBlank
        zest.vblank.start
            zest.mockVdpStatusFlags zest.VDP_VBLANK_STATUS
            ret
        zest.vblank.end

        zest.initRegisters

        utils.preserve
            interrupts.waitForVBlank
        utils.restore

        expect.all.toBeUnclobberedExcept "af"
