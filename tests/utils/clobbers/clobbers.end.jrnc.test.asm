describe "utils.clobbers.end.jrnc"
    test "does not jump or restore when carry is set"
        jr +
            -:
            zest.fail "Unexpected jump"
        +:

        ; Set all registers to $FF
        ld a, $ff
        call suite.registers.setAllToA

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags    ; set carry

                ; This shouldn't jump
                utils.clobbers.end.jrnc -

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end
        utils.restore

    test "restores and jumps when carry is reset"
        zest.initRegisters

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Zero registers
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags  ; reset carry flag

                ; Expect this to jump
                utils.clobbers.end.jrnc +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            expect.all.toBeUnclobbered
        utils.restore

describe "utils.clobbers.end.jrnc with nothing to restore"
    test "does not jump or restore when carry is set"
        jr +
            -:
            zest.fail "Unexpected jump"
        +:

        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags

                ; This shouldn't jump
                utils.clobbers.end.jrnc -

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end
        utils.restore

    test "jumps but doesn't restore when carry is reset"
        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero, but set Z flag
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags

                ; Expect this to jump
                utils.clobbers.end.jrnc +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            ; Expect values to still be zero
            call suite.registers.expectAllToBeZero
        utils.restore
