describe "tilemap.ifColScrollElseRet"
    .redefine utils.registers.AUTO_PRESERVE 1

    test "jumps to the left label when left col scroll needed"
        tilemap.reset
        ld a, -8
        tilemap.adjustXPixels
        tilemap.calculateScroll

        zest.initRegisters

        call +
        zest.fail "Unexpected return"

        +:

        tilemap.ifColScrollElseRet, ++, +++
            ++:
                ; Left
                expect.all.toBeUnclobbered
                jp ++++ ; pass
            +++:
                zest.fail "Right called"
        ++++: ; pass

    test "jumps to the right label when right col scroll needed"
        tilemap.reset
        ld a, 8
        tilemap.adjustXPixels
        tilemap.calculateScroll

        zest.initRegisters

        call +
        zest.fail "Unexpected return"

        +:

        tilemap.ifColScrollElseRet, ++, +++
            ++:
                ; Left
                zest.fail "Left called"
            +++:
                ; Right
                expect.all.toBeUnclobbered

    test "returns when no col scroll needed"
        tilemap.reset
        zest.initRegisters

        call +
        expect.all.toBeUnclobbered
        jp +++  ; pass

        +:
        tilemap.ifColScrollElseRet, +, ++
            +:
                ; Left
                zest.fail "Left called"
            ++:
                ; Right
                zest.fail "Right called"
        +++: ; pass

.redefine utils.registers.AUTO_PRESERVE 0
