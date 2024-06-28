describe "tilemap.ifRowScrollElseRet"
    .redefine utils.registers.AUTO_PRESERVE 1

    test "jumps to the up label when up row scroll needed"
        tilemap.reset
        ld a, -8
        tilemap.adjustYPixels
        tilemap.calculateScroll

        zest.initRegisters

        call +
        zest.fail "Unexpected return"

        +:

        tilemap.ifRowScrollElseRet, ++, +++
            ++:
                ; Up
                expect.all.toBeUnclobbered
                jp ++++ ; pass
            +++:
                zest.fail "Down called"
        ++++:

    test "jumps to the down label when down row scroll needed"
        tilemap.reset
        ld a, 8
        tilemap.adjustYPixels
        tilemap.calculateScroll

        zest.initRegisters

        call +
        zest.fail "Unexpected return"

        +:

        tilemap.ifRowScrollElseRet, ++, +++
            ++:
                zest.fail "Up called"
            +++:
                ; Down
                expect.all.toBeUnclobbered

    test "returns when no row scroll needed"
        tilemap.reset
        zest.initRegisters

        call +
        expect.all.toBeUnclobbered
        jp +++  ; pass

        +:
        tilemap.ifRowScrollElseRet, +, ++
            +:
                ; Up
                zest.fail "Up called"
            ++:
                ; Down
                zest.fail "Down called"
        +++:

.redefine utils.registers.AUTO_PRESERVE 0
