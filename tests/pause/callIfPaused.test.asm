describe "pause.callIfPaused"
    test "calls the given routine if the pause flag is set"
        ; Set pause flag
        ld a, 1
        ld (pause.ram.pauseFlag), a

        jr +
            -:
            jp ++   ; routine called; jp to pass
        +:

        pause.callIfPaused -
        zest.fail "Did not call"
        ++:

    test "does not call the routine if the pause flag is reset"
        ; Reset pause flag
        xor a
        ld (pause.ram.pauseFlag), a

        jr +
            -:
            zest.fail "Unexpected call"
        +:

        pause.callIfPaused -
