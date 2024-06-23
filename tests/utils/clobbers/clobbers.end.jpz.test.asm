describe "utils.clobbers.end.jpz"
    test "when NZ - does not jump or restore"
        ; Set all registers to $FF
        ld a, $ff
        call suite.registers.setAllToA

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags  ; set NZ

                ; This shouldn't jump
                utils.clobbers.end.jpz suite.registers.unexpectedJump

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end
        utils.restore

    test "when Z - restores and jumps"
        zest.initRegisters

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Zero registers but set Z flag
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags

                ; Expect this to jump
                utils.clobbers.end.jpz +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            expect.all.toBeUnclobbered
        utils.restore

describe "utils.clobbers.end.jpz with nothing to restore"
    test "when NZ - does not jump or restore"
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
                call suite.registers.resetAllFlags

                ; This shouldn't jump
                utils.clobbers.end.jpz suite.registers.unexpectedJump

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end
        utils.restore

    test "when Z - jumps but doesn't restore"
        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero, but set Z flag
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags

                ; Expect this to jump
                utils.clobbers.end.jpz +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            ; Expect values to still be zero
            call suite.registers.expectAllToBeZero
        utils.restore
