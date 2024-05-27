describe "register preservation"
    ; Deactivate AUTO_PRESERVE
    .redefine registers.AUTO_PRESERVE 0

    test "should not preserve any registers if no preserve scopes are in progress"
        registers.clobbers "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
            expect.stack.size.toBe 0
        registers.clobberEnd

    test "preserves all registers marked as clobbered"
        zest.initRegisters

        ; Preserve all registers
        registers.preserve "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
            ; This clobber scope clobbers all registers
            registers.clobbers "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
                call suite.clobberAll
            registers.clobberEnd
        registers.restore

        ; Expect all registers to have been preserved
        expect.all.toBeUnclobbered

    test "only preserves the requested registers"
        ld bc, $bc01
        ld de, $de01
        ld hl, $ffff

        ; Preserve BC and DE only
        registers.preserve "bc", "de"
            ; This clobber scope clobbers all registers
            registers.clobbers "bc", "de", "hl"
                ld bc, 0
                ld de, 0
                ld hl, 0
            registers.clobberEnd
        registers.restore

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
        registers.preserve "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
            ; This clobber scope only clobbers DE and HL
            registers.clobbers "bc", "de"
                ld bc, 0
                ld de, 0
                ld hl, 0
            registers.clobberEnd
        registers.restore

        ; Expect BC and DE to have been preserved
        expect.bc.toBe $bc01
        expect.de.toBe $de01

        ; Expect HL to have been clobbered
        expect.hl.toBe 0

    test "only preserves registers once per preserve context"
        ld bc, $bc01

        ; Preserve BC
        registers.preserve "bc"
            ; Nothing should have been preserved yet
            expect.stack.size.toBe 0

            ; This clobber scope clobbers BC
            registers.clobbers "bc"
                ; Expect BC to have been pushed to the stack
                expect.stack.size.toBe 1
                expect.stack.toContain $bc01

                ld bc, $bc02

                ; This inner clobber scope also clobbers BC
                registers.clobbers "bc"
                    ; The outer scope has already preserved BC in the stack,
                    ; so expect this not to have pushed it again
                    expect.stack.size.toBe 1 "Expected stack size to still be 1"
                    expect.stack.toContain $bc01 0 "Expected stack to still contain the original value"

                    ld bc, $bc03
                registers.clobberEnd
            registers.clobberEnd
        registers.restore

        expect.stack.size.toBe 0 "Expected stack size to be back to 0"
        expect.bc.toBe $bc01
