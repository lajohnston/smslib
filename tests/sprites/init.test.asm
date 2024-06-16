describe "sprites.init"
    test "sets the nextIndex to $40"
        ld a, $ff
        ld (sprites.ram.buffer.nextIndex), a

        sprites.init

        ld a, (sprites.ram.buffer.nextIndex)
        expect.a.toBe $40

    test "does not clobber any registers"
        zest.initRegisters

        utils.registers.preserve
            sprites.init
        utils.registers.restore

        expect.all.toBeUnclobbered