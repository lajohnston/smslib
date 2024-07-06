describe "pause.waitIfPaused"
    test "does not clobber any registers"
        ; Reset pause flag
        xor a
        ld (pause.ram.pauseFlag), a

        zest.initRegisters

        utils.preserve
            pause.waitIfPaused
        utils.restore

        expect.all.toBeUnclobbered