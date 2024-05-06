describe "register preservation: nested preserve scopes"
    test "preserves registers for each preserve scope"
        ld a, $01
        call suite.setAllToA

        ; Preserve all registers (containing $01)
        registers.preserve
            ; Clob all registers
            registers.clobbers "ALL"
                ld a, $02
                call suite.setAllToA

                ; Preserve all registers again (containing $02)
                registers.preserve
                    ; Clob all registers with $03
                    registers.clobbers "ALL"
                        ld a, $03
                        call suite.setAllToA
                    registers.clobberEnd
                registers.restore

                ; Expect registers to be back to $02 after inner context
                expect.a.toBe $02
                expect.bc.toBe $0202
                expect.de.toBe $0202
                expect.hl.toBe $0202
                expect.ix.toBe $0202
                expect.iy.toBe $0202
                expect.i.toBe $02
            registers.clobberEnd
        registers.restore

        ; Expect all registers to be back to $01 after outer context
        expect.a.toBe $01
        expect.bc.toBe $0101
        expect.de.toBe $0101
        expect.hl.toBe $0101
        expect.ix.toBe $0101
        expect.iy.toBe $0101
        expect.i.toBe $01

    test "preserves registers required by ancestor scopes"
        ld bc, $bc01
        ld de, $de01
        ld hl, $ff01

        ; Outer context requires BC to be preserved
        registers.preserve "BC"
            ; Outer context requires DE to be preserved
            registers.preserve "DE"
                ; Nothing clobbered or preserved so far
                expect.stack.size.toBe 0

                ; Inner context preserves HL
                registers.preserve "HL"
                    ; This clobber scope clobbers all three pairs
                    registers.clobbers "BC" "DE" "HL"
                        expect.stack.size.toBe 3
                        ld bc, $bc02
                        ld de, $de02
                        ld hl, $ff02
                    registers.clobberEnd
                registers.restore

                expect.hl.toBe $ff01    ; back to original
            registers.restore

            expect.de.toBe $de01    ; back to original
        registers.restore

        expect.bc.toBe $bc01

    test "does not preserve registers from ancestor scopes if they've already been preserved"
        ld bc, $bc01
        ld de, $de01

        ; Outer context requires BC to be preserved
        registers.preserve "BC"
            ; Clob scope clobbers BC
            registers.clobbers "BC"
                ; Expect BC to have been preserved by this point
                expect.stack.size.toBe 1
                expect.stack.toContain $bc01
                ld bc, $bc02

                ; Inner scope requires DE to be preserved
                registers.preserve "DE"
                    ; This clobber scope clobbers both BC and DE
                    registers.clobbers "BC" "DE"
                        ; DE shouldn't be preserved again as the outer clobberStart
                        ; has already done so
                        expect.stack.size.toBe 2
                        expect.stack.toContain $de01    ; original value of DE
                        expect.stack.toContain $bc01 1  ; original value of BC

                        ld de, $de02
                    registers.clobberEnd
                registers.restore

                expect.de.toBe $de01
            registers.clobberEnd
        registers.restore

        expect.bc.toBe $bc01
