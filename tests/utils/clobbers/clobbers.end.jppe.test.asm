describe "utils.clobbers.end.jppe"
    test "does not jump or restore when parity/overflow is reset"
        ; Set all registers to $FF
        ld a, $ff
        call suite.registers.setAllToA

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags  ; reset parity/overflow

                ; This shouldn't jump
                utils.clobbers.end.jppe suite.registers.unexpectedJump

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end
        utils.restore

    test "restores and jumps when parity/overflow is set"
        zest.initRegisters

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Zero registers
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags    ; set parity/overflow flag

                ; Expect this to jump
                utils.clobbers.end.jppe +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            expect.all.toBeUnclobbered
            expect.stack.size.toBe 0
        utils.restore

describe "utils.clobbers.end.jppe with nothing to restore"
    test "does not jump or restore when parity/overflow is reset"
        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags  ; set parity/overflow

                ; This shouldn't jump
                utils.clobbers.end.jppe suite.registers.unexpectedJump

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end

            expect.stack.size.toBe 0
        utils.restore

    test "jumps but doesn't restore when parity/overflow is set"
        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero, but set parity flag
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags

                ; Expect this to jump
                utils.clobbers.end.jppe +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            ; Expect values to still be zero
            call suite.registers.expectAllToBeZero
            expect.stack.size.toBe 0
        utils.restore
