;====
; Adjusts the buffered tilemap yScroll value by a given number of pixels. If
; this results in a new row needing to be drawn it sets flags in RAM indicating
; whether the top or bottom rows need re-writing. You can interpret these flags
; using tilemap.ifRowScroll.
;
; The scroll value won't apply until you call tilemap.writeScrollRegisters
;
; @in   a   the number of y pixels to adjust. Positive values scroll down in
;           the game world (shifting the tiles up). Negative values scroll
;           up (shifting the tiles down)
;====
.macro "tilemap.adjustYPixels"
    \@_\.:
    utils.clobbers "af" "bc" "hl"
        call tilemap._adjustYPixels
    utils.clobbers.end
.endm

;====
; See tilemap.adjustYPixels macro
;
; - Updates tilemap.ram.flags with relevant up/down scroll flags
;
; @in   a   the number of y pixels to adjust. Positive values scroll down in
;           the game world (shifting the tiles up). Negative values scroll
;           up (shifting the tiles down)
;====
.section "tilemap._adjustYPixels" free
    tilemap._adjustYPixels:
        or a                    ; analyse yAdjust
        jp z, _noRowScroll      ; jump if nothing to adjust

        ld hl, tilemap.ram.yScrollBuffer    ; point to yScrollBuffer
        ld c, (hl)              ; load current yScrollBuffer into C
        jp p, _movingDown       ; jump to _movingDown if yAdjust is positive

    _movingUp:
        add a, c                ; add yAdjust to yScrollBuffer
        cp tilemap.Y_PIXELS     ; check if value has gone out of range
        jp c, +
            ; Value is out of range
            sub 256 - tilemap.Y_PIXELS  ; bring into range (i.e. -1/255 becomes 223)
            ld (hl), a                  ; store new yScrollBuffer

            ; Check if scroll needed
            xor c                   ; compare yScrollBuffer against old value in C
            and %11111000           ; zero lower bits (we only care about upper 5)
            jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

            ; Update scroll flags
            ld hl, tilemap.ram.flags        ; point to flags
            ld a, (hl)                      ; load flags into A
            and tilemap.SCROLL_Y_RESET_MASK ; reset previous y scroll flags
            or tilemap.SCROLL_UP_SET_MASK   ; set new scroll flag
            ld (hl), a                      ; store result
            ret
        +:

        ; Value is in range
        ld (hl), a                          ; store new yScrollBuffer

        ; If upper 5 bits change, row scroll needed
        xor c                   ; compare yScrollBuffer against old value in C
        and %11111000           ; zero lower bits (we only care about upper 5)
        jp z, _noRowScroll      ; jump if zero (if upper 5 bits are the same)

        ; Update scroll flags
        dec hl                          ; point to flags
        ld a, (hl)                      ; load flags into A
        and tilemap.SCROLL_Y_RESET_MASK ; reset previous y scroll flags
        or tilemap.SCROLL_UP_SET_MASK   ; set new scroll flag
        ld (hl), a                      ; store result
        ret

    _movingDown:
        add a, c                    ; add yAdjust to yScrollBuffer
        cp tilemap.Y_PIXELS         ; check if value has gone out of range
        jp c, +
            ; Value is out of range
            sub tilemap.Y_PIXELS    ; bring back into range (i.e. 224 becomes 0)
            ld (hl), a              ; store new yScrollBuffer

            ; If upper 5 bits change, row scroll needed
            xor c                   ; compare yScrollBuffer against old value in C
            and %11111000           ; zero lower bits (we only care about upper 5)
            jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

            ; Update scroll flags
            ld hl, tilemap.ram.flags        ; point to flags
            ld a, (hl)                      ; load flags into A
            or tilemap.SCROLL_DOWN_SET_MASK ; update scroll flag
            ld (hl), a                      ; store result
            ret
        +:

        ; Value is in range
        ld (hl), a              ; store new yScrollBuffer

        ; If upper 5 bits change, row scroll needed
        xor c                   ; compare yScrollBuffer against old value in C
        and %11111000           ; zero lower bits (we only care about upper 5)
        jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

        ; Update scroll flags
        dec hl                          ; point to flags
        ld a, (hl)                      ; load flags into A
        or tilemap.SCROLL_DOWN_SET_MASK ; update scroll flag
        ld (hl), a                      ; store result
        ret

    _noRowScroll:
        ld hl, tilemap.ram.flags
        ld a, tilemap.SCROLL_Y_RESET_MASK
        and (hl)            ; reset Y scroll flags with mask
        ld (hl), a          ; update flags
        ret
.ends
