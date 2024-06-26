describe "tilemap.ifColScroll with 1 arg (else label)"
    .redefine utils.registers.AUTO_PRESERVE 1

    test "jumps to the label if no scroll is needed"
        tilemap.reset

        zest.initRegisters

        tilemap.ifColScroll +
            zest.fail "ifColScroll was true"
        +:

        expect.all.toBeUnclobbered

    test "does not jump to the given label if a left scroll is needed"
        tilemap.reset
        ld a, -8
        tilemap.adjustXPixels
        tilemap.calculateScroll

        zest.initRegisters

        tilemap.ifColScroll +
            expect.all.toBeUnclobbered
            jr ++ ; pass
        +:

        zest.fail "ifColScroll was false"

        ++:

    test "does not jump to the given label if a right scroll is needed"
        tilemap.reset
        ld a, 8
        tilemap.adjustXPixels
        tilemap.calculateScroll

        zest.initRegisters

        tilemap.ifColScroll +
            expect.all.toBeUnclobbered
            jr ++ ; pass
        +:

        zest.fail "ifColScroll was false"

        ++:

describe "tilemap.ifColScroll with left, right, else args"
    test "jumps to the left label when no col scroll needed"
        tilemap.reset
        ld a, -8
        tilemap.adjustXPixels
        tilemap.calculateScroll

        zest.initRegisters

        tilemap.ifColScroll, +, ++, +++
            +:  ; Left
                expect.all.toBeUnclobbered
                jp ++++ ; pass
            ++:
                zest.fail "Right called"
            +++:
                zest.fail "Else called"
        ++++: ; pass

    test "jumps to the left label when no col scroll needed"
        tilemap.reset
        ld a, 8
        tilemap.adjustXPixels
        tilemap.calculateScroll

        zest.initRegisters

        tilemap.ifColScroll, +, ++, +++
            +:
                zest.fail "Left called"
            ++: ; Right
                expect.all.toBeUnclobbered
                jp ++++ ; pass
            +++:
                zest.fail "Else called"
        ++++: ; pass

    test "jumps to else label when no col scroll needed"
        tilemap.reset
        zest.initRegisters

        tilemap.ifColScroll, +, ++, +++
            +:
                zest.fail "Left called"
            ++:
                zest.fail "Right called"
        +++:

        expect.all.toBeUnclobbered

.redefine utils.registers.AUTO_PRESERVE 0
