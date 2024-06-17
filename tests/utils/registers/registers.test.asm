describe "register preservation"
    ; Deactivate AUTO_PRESERVE
    .redefine utils.registers.AUTO_PRESERVE 0

    test "preserves all clobbered registers by default"
        zest.initRegisters

       utils.preserve  ; no registers - preserve all by default
           utils.clobbers "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
                call suite.registers.clobberAll
           utils.clobbers.end
       utils.restore

        expect.all.toBeUnclobbered

    test "should not preserve any registers if no preserve scopes are in progress"
       utils.clobbers "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
            expect.stack.size.toBe 0
       utils.clobbers.end

    test "preserves all registers marked as clobbered"
        zest.initRegisters

        ; Preserve all registers
       utils.preserve "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
            ; This clobber scope clobbers all registers
           utils.clobbers "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
                call suite.registers.clobberAll
           utils.clobbers.end
       utils.restore

        ; Expect all registers to have been preserved
        expect.all.toBeUnclobbered

    test "only preserves the requested registers"
        ld bc, $bc01
        ld de, $de01
        ld hl, $ffff

        ; Preserve BC and DE only
       utils.preserve "bc", "de"
            ; This clobber scope clobbers all registers
           utils.clobbers "bc", "de", "hl"
                ld bc, 0
                ld de, 0
                ld hl, 0
           utils.clobbers.end
       utils.restore

        ; Expect BC and DE to have been preserved
        expect.bc.toBe $bc01
        expect.de.toBe $de01

        ; Expect HL to have been clobbered
        expect.hl.toBe 0

    test "only preserves registers marked as clobbered"
        ld bc, $bc01
        ld de, $de01
        ld hl, $ffff

        ; Preserve all registers
       utils.preserve "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
            ; This clobber scope only clobbers DE and HL
           utils.clobbers "bc", "de"
                ld bc, 0
                ld de, 0
                ld hl, 0
           utils.clobbers.end
       utils.restore

        ; Expect BC and DE to have been preserved
        expect.bc.toBe $bc01
        expect.de.toBe $de01

        ; Expect HL to have been clobbered
        expect.hl.toBe 0

    test "only preserves registers once per preserve context"
        ld bc, $bc01

        ; Preserve BC
       utils.preserve "bc"
            ; Nothing should have been preserved yet
            expect.stack.size.toBe 0

            ; This clobber scope clobbers BC
           utils.clobbers "bc"
                ; Expect BC to have been pushed to the stack
                expect.stack.size.toBe 1
                expect.stack.toContain $bc01

                ld bc, $bc02

                ; This inner clobber scope also clobbers BC
               utils.clobbers "bc"
                    ; The outer scope has already preserved BC in the stack,
                    ; so expect this not to have pushed it again
                    expect.stack.size.toBe 1 "Expected stack size to still be 1"
                    expect.stack.toContain $bc01 0 "Expected stack to still contain the original value"

                    ld bc, $bc03
               utils.clobbers.end
           utils.clobbers.end
       utils.restore

        expect.stack.size.toBe 0 "Expected stack size to be back to 0"
        expect.bc.toBe $bc01
