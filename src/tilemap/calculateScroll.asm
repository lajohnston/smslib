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

        ; Save index
        ld (tilemap.ram.colWriteIndex), a

        ret
.ends
