;====
; Calculates the adjustments made with tilemap.adjustXPixels/adjustYPixels
; and applies them to the RAM variables
;====
.macro "tilemap.calculateScroll"
    \@_\.:
    utils.clobbers "af" "bc"
        call tilemap._calculateScroll
    utils.clobbers.end
.endm

;====
; Calculates the adjustments made with tilemap.adjustXPixels/adjustYPixels
; and applies them to the RAM variables.
;
; Sets tilemap.ram.vramRowWrite to the VRAM write address if up/down scroll
; flags are set, otherwise it's left unchanged
;====
.section "tilemap._calculateScroll" free
    tilemap._calculateScroll:
        ld a, (tilemap.ram.flags)   ; load scroll flags in A
        ld c, a                     ; preserve flags in C

    _updateRowScroll:
        ; Check Y scroll flag
        rrca                        ; set C to bit 0
        jp nc, _updateColScroll     ; bit 0 was 0; no rows to scroll

        ; Check down scroll
        rrca                        ; set C to what was bit 1
        jp c, _scrollingDown        ; jp if bit 1 was 1 (scrolling down)

        _scrollingUp:
            ; Set row to vramRow; Set col to 0
            ld a, (tilemap.ram.yScrollBuffer)   ; load scroll value

            ; Divide by 8 (3x rrca) and rotate right twice (2x rrca)
            ; 3x rlca (left rotate) is equivalent to 5x rrca (right rotate)
            rlca
            rlca
            rlca                    ; value is now y1y0---y4y3y2

            ld b, a                 ; preserve in B
            and %00000111           ; mask y4,y3,y2
            or %01000000 | >tilemap.VRAM_ADDRESS    ; set base address + write command
            ld h, a                 ; store in H
            ld a, b                 ; restore rotated Y (y1y0---y4y3y2)
            and %11000000           ; mask y1y0
            ld l, a                 ; store in L
            ld (tilemap.ram.vramRowWrite), hl   ; set vramRowWrite
            jp _updateColScroll

        _scrollingDown:
            ; Set col to 0; Set row to (vramRow + 24) mod total rows;
            ld a, (tilemap.ram.yScrollBuffer)
            rrca                    ; divide by 2
            rrca                    ; ...divide by 4
            rrca                    ; ...divide by 8 - lower 5 bits is now row number
            and %00011111           ; floor result

            ; Calculate bottom visible row
            add tilemap.MIN_VISIBLE_ROWS
            cp tilemap.ROWS         ; compare against number of rows
            jp c, ++
                ; Row number has overflowed max value - wrap value
                sub tilemap.ROWS
            ++:

            rrca                    ; rotate row/y right
            rrca                    ; rotate right again (y1y0---y4y3y2)
            ld b, a                 ; preserve in B
            and %00000111           ; mask y4,y3,y2
            or %01000000 | >tilemap.VRAM_ADDRESS    ; add base address + write command
            ld h, a                 ; store in H
            ld a, b                 ; restore rotated Y (y1y0---y4y3y2) into A
            and %11000000           ; mask y1y0
            ld l, a                 ; store in L
            ld (tilemap.ram.vramRowWrite), hl   ; set vramRowWrite
            ; ... continue to _updateColScroll
        +:

    ;===
    ; @in   c   scroll flags
    ;===
    _updateColScroll:
        ; Check left or right scroll
        ld a, c         ; load flags into A
        rlca            ; set C to bit 7
        ret nc          ; if bit 7 was 0, no column scroll needed

        ; Get top row (yScroll / 8), multiplied by 2 bytes per lookup item
        ld a, (tilemap.ram.yScrollBuffer)
        rrca            ; divide by 2
        rrca            ; divide by 2 again. Bits 1-5 now equal row * 2
        and %00111110   ; clean value

        ; Point HL to item in lookup table
        ld hl, tilemap._writeColumnLookup
        add l           ; add L to row offset in A
        ld l, a         ; store result in L

        ; Set HL to (HL)
        ld a, (hl)      ; load low byte into A
        inc l           ; point to high byte
        ld h, (hl)      ; load high byte into H
        ld l, a         ; load low byte into L

        ; Save colWriteCall
        ld (tilemap.ram.colWriteCall), hl
        ret
.ends

;====
; Lookup table for the loop iterations in tilemap._writeColumn
; Usage: load HL with tilemap._writeColumnLookup then add row * 2 to L; HL will
; then point to the address to call in the loop
;=====
.section "tilemap._writeColumnLookup" free bitwindow 8
    tilemap._writeColumnLookup:
        ; The offset to the current tilemap._writeColumn iteration
        .redefine tilemap._writeColumnLookup_currentOffset 0

        ; Iterate over each potential row, starting from 0
        .repeat tilemap.ROWS index rowNumber
            ; Set address of the row iteration in tilemap._writeColumn
            .dw tilemap._writeColumn + tilemap._writeColumnLookup_currentOffset

            ; Update offset to next iteration
            .if rowNumber # 2 == 0
                ; Every second iteration uses additional optimisations, so we
                ; only need to increase the offset by 12 bytes
                .redefine tilemap._writeColumnLookup_currentOffset tilemap._writeColumnLookup_currentOffset + 12
            .else
                ; Increase offset by 14 bytes
                .redefine tilemap._writeColumnLookup_currentOffset tilemap._writeColumnLookup_currentOffset + 14
            .endif
        .endr
.ends

;====
; Unrolled loop of column tile writes. Call one of the addresses stored in the
; tilemap._writeColumnLookup lookup table to start from a given row. The loop
; will wrap back to 0 after the 28th tile is written and continue until all
; bytes are written
;
; @in   hl  pointer to sequential tile data
; @in   b   bytes to write (number of rows * 2)
; @in   d   column number * 2 ORed with 128
; @in   e   column number * 2
;====
.section "tilemap._writeColumn" free
    tilemap._writeColumn:
        .repeat tilemap.ROWS index rowNumber
            ; Calculate write address for column 0
            .redefine tilemap._writeColumn_writeAddress ($4000 | tilemap.VRAM_ADDRESS) + (rowNumber * tilemap.COLS * tilemap.TILE_SIZE_BYTES)
            .redefine tilemap._writeColumn_writeAddressHigh >tilemap._writeColumn_writeAddress
            .redefine tilemap._writeColumn_writeAddressLow <tilemap._writeColumn_writeAddress

            ; Calculate VRAM low byte write address (0, 64, 128, 192)
            .if tilemap._writeColumn_writeAddressLow == 0
                ; Row address low byte is 0; Just set A to column address
                ld a, e ; set A to column address
            .elif tilemap._writeColumn_writeAddressLow == 128
                ; Row address low byte is 128; This value (and col address) is cached in D
                ld a, d
            .else
                ; Set A to low address
                ld a, tilemap._writeColumn_writeAddressLow

                ; Set column address bits
                or e
            .endif

            ; Set VRAM low byte write address
            out (utils.vdpCommand.COMMAND_PORT), a

            ; Set VRAM high byte write address
            ld a,  tilemap._writeColumn_writeAddressHigh; set A to high address
            out (utils.vdpCommand.COMMAND_PORT), a  ; send to VDP

            ; Write tile
            outi    ; pattern ref
            outi    ; tile attributes
            ret z   ; return if no more tiles to write (B = 0)
        .endr

        jp tilemap._writeColumn  ; continue from row 0
.ends
