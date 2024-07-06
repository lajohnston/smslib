describe "pause.jpIfPaused"
    test "jumps if the pause flag is set"
        ; Set pause flag
        ld a, 1
        ld (pause.ram.pauseFlag), a

        pause.jpIfPaused +
        zest.fail "Did not jump"
        +:

    test "does not jump if the pause flag is reset"
        ; Reset pause flag
        xor a
        ld (pause.ram.pauseFlag), a

        pause.jpIfPaused +
        jp ++   ; did not jump; jump to pass

        +:
        zest.fail "Unexpected jump"

        ++: ; pass
