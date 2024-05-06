describe "automatic register preservation"
    ; Activate AUTO_PRESERVE
    .redefine registers.AUTO_PRESERVE 1

    test "preserves all clobbered registers"
        ld a, $08
        call suite.setAllToA
        scf

        registers.clobbers "ALL"
            ld a, $ff
            ccf
            call suite.setAllToA
        registers.clobberEnd

        ; Expect all registers to have been preserved
        expect.a.toBe $08
        expect.carry.toBe 1
        expect.bc.toBe $0808
        expect.de.toBe $0808
        expect.hl.toBe $0808
        expect.ix.toBe $0808
        expect.iy.toBe $0808

    test "preserves all clobbered shadow registers"
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

        ; Expect all shadow registers to have been preserved
        ex af, af'
        exx
        expect.a.toBe $aa
        expect.carry.toBe 1
        expect.bc.toBe $bbbb
        expect.de.toBe $cccc
        expect.hl.toBe $dddd

    test "only preserves clobbered registers"
        ld a, $08
        call suite.setAllToA

        ld bc, $bc01
        ld de, $de01

        registers.clobbers "BC"
            expect.stack.size.toBe 1
            expect.stack.toContain $bc01
        registers.clobberEnd

        registers.clobbers "BC" "DE"
            expect.stack.size.toBe 2
            expect.stack.toContain $de01
            expect.stack.toContain $bc01 1
        registers.clobberEnd

    test "only preserves registers once if there are nested preserve scopes"
        registers.clobbers "AF"
            expect.stack.size.toBe 1

            registers.clobbers "AF"
                expect.stack.size.toBe 1 "Expected stack size to still be 1"
            registers.clobberEnd
        registers.clobberEnd

    test "does not override existing preserve scopes"
        ld a, 0
        call suite.setAllToA

        ; Preserve scope already exists - this should not be overridden
        registers.preserve "BC"
            ; Clobber scope clobbers all registers
            registers.clobbers "ALL"
                ; Only BC should have been preserved
                expect.stack.size.toBe 1
                expect.stack.toContain $0000

                ; Clob registers
                ld a, $ff
                call suite.setAllToA
            registers.clobberEnd
        registers.restore

        expect.bc.toBe 0

        ; Expect rest to have been clobbered
        expect.a.toBe $ff
        expect.de.toBe $ffff
        expect.hl.toBe $ffff
        expect.ix.toBe $ffff
        expect.iy.toBe $ffff
