describe "tilemap.ifRowScroll with 1 arg (else label)"
    .redefine utils.registers.AUTO_PRESERVE 1

    test "jumps to the label if no scroll is needed"
        tilemap.reset

        zest.initRegisters

        tilemap.ifRowScroll +
            zest.fail "ifRowScroll was true"
        +:

        expect.all.toBeUnclobbered

    test "does not jump to the given label if an up row scroll is needed"
        tilemap.reset
        ld a, -8
        tilemap.adjustYPixels
        tilemap.calculateScroll

        zest.initRegisters

        tilemap.ifRowScroll +
            expect.all.toBeUnclobbered
            jr ++ ; pass
        +:

        zest.fail "ifRowScroll was false"

        ++:

    test "does not jump to the given label if a down scroll is needed"
        tilemap.reset
        ld a, 8
        tilemap.adjustYPixels
        tilemap.calculateScroll

        zest.initRegisters

        tilemap.ifRowScroll +
            expect.all.toBeUnclobbered
            jr ++ ; pass
        +:

        zest.fail "ifRowScroll was false"

        ++:

describe "tilemap.ifRowScroll with up, down, else args"
    test "jumps to the up label when up col scroll needed"
        tilemap.reset
        ld a, -8
        tilemap.adjustYPixels
        tilemap.calculateScroll

        zest.initRegisters

        tilemap.ifRowScroll, +, ++, +++
            +:  ; up
                expect.all.toBeUnclobbered
                jp ++++ ; pass
            ++:
                zest.fail "Down called"
            +++:
                zest.fail "Else called"
        ++++: ; pass

    test "jumps to the down label when down scroll needed"
        tilemap.reset
        ld a, 8
        tilemap.adjustYPixels
        tilemap.calculateScroll

        zest.initRegisters

        tilemap.ifRowScroll, +, ++, +++
            +:
                zest.fail "Up called"
            ++: ; down
                expect.all.toBeUnclobbered
                jp ++++ ; pass
            +++:
                zest.fail "Else called"
        ++++: ; pass

    test "jumps to else label when no col scroll needed"
        tilemap.reset
        zest.initRegisters

        tilemap.ifRowScroll, +, ++, +++
            +:
                zest.fail "Up called"
            ++:
                zest.fail "Down called"
        +++:

        expect.all.toBeUnclobbered

.redefine utils.registers.AUTO_PRESERVE 0
