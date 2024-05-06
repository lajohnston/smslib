describe "register preservation"
    ; Deactivate AUTO_PRESERVE
    .redefine registers.AUTO_PRESERVE 0

    test "should not preserve any registers if no preserve scope are in progress"
        registers.clobbers "ALL"
            expect.stack.size.toBe 0
        registers.clobberEnd

    test "preserves registers marked as clobbered"
        ld a, $aa
        scf
        ld i, a
        ld bc, $bbbb
        ld de, $cccc
        ld hl, $dddd
        ld ix, $eeee
        ld iy, $ffff

        ; Preserve all registers
        registers.preserve
            ; This clobber scope clobbers all registers
            registers.clobbers "ALL"
                ld a, $05
                call suite.setAllToA
                ccf
            registers.clobberEnd
        registers.restore

        ; Expect all registers to have been preserved
        expect.a.toBe $aa
        expect.carry.toBe 1
        expect.bc.toBe $bbbb
        expect.de.toBe $cccc
        expect.hl.toBe $dddd
        expect.ix.toBe $eeee
        expect.iy.toBe $ffff
        expect.i.toBe $aa

    test "preserves shadow registers marked as clobbered"
        ; Initialise shadow registers
        ex af, af'
        ld a, $aa
        scf
        exx
        ld bc, $bbbb
        ld de, $cccc
        ld hl, $dddd

        ; Switch back to main registers
        ex af, af'
        exx

        ; Preserve all registers
        registers.preserve "AF'" "BC'" "DE'" "HL'"
            ; This clobber scope clobbers all registers
            registers.clobbers "AF'" "BC'" "DE'" "HL'"
                ; Routine switches to shadow registers and clobbers them
                ex af, af'
                exx
                ld a, $05
                call suite.setAllToA
                ccf

                ; Routine switches them back to the shadows
                ex af, af'
                exx
            registers.clobberEnd
        registers.restore

        ; Expect all shadow registers to have been preserved
        ex af, af'
        exx
        expect.a.toBe $aa
        expect.carry.toBe 1
        expect.bc.toBe $bbbb
        expect.de.toBe $cccc
        expect.hl.toBe $dddd

    test "only preserves the requested registers"
        ld a, 1
        call suite.setAllToA

        ; Preserve BC and DE only
        registers.preserve "BC" "DE"
            ; This clobber scope clobbers all registers
            registers.clobbers "ALL"
                ld a, $ff
                call suite.setAllToA
            registers.clobberEnd
        registers.restore

        ; Expect BC and DE to have been preserved
        expect.bc.toBe $0101
        expect.de.toBe $0101

        ; Expect the rest to have been clobbered
        expect.a.toBe $ff
        expect.hl.toBe $ffff
        expect.ix.toBe $ffff
        expect.iy.toBe $ffff
        expect.i.toBe $ff

    test "only preserves registers marked as clobbered"
        ld a, 1
        call suite.setAllToA

        ; Preserve all registers
        registers.preserve "ALL"
            ; This clobber scope only clobbers DE and HL
            registers.clobbers "DE" "HL"
                expect.stack.size.toBe 2    ; DE and HL should have been pushed
                ld a, $ff
                call suite.setAllToA
            registers.clobberEnd
        registers.restore

        ; Expect DE and HL to have been preserved
        expect.de.toBe $0101
        expect.hl.toBe $0101

        ; Expect the rest to have been clobbered
        expect.a.toBe $ff
        expect.bc.toBe $ffff
        expect.ix.toBe $ffff
        expect.iy.toBe $ffff
        expect.i.toBe $ff

    test "only preserves registers once per preserve context"
        ld bc, $bc01

        ; Preserve BC
        registers.preserve "BC"
            ; Nothing should have been preserved yet
            expect.stack.size.toBe 0

            ; This clobber scope clobbers BC
            registers.clobbers "BC"
                ; Expect BC to have been pushed to the stack
                expect.stack.size.toBe 1
                expect.stack.toContain $bc01

                ld bc, $bc02

                ; This inner clobber scope also clobbers BC
                registers.clobbers "BC"
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

        ld bc, $bc01

        ; Requires BC to be preserved
        registers.preserve "BC"
            ; Also BC to be preserved
            registers.clobbers "BC"
                ld bc, $bc02    ; first clob

                ; Inner preserve - should preserve $bc02
                registers.preserve "BC"
                    registers.clobbers "BC"
                        ld bc, $bc03    ; second clob
                    registers.clobberEnd
                registers.restore

                expect.bc.toBe $bc02
            registers.clobberEnd
        registers.restore

        expect.bc.toBe $bc01
