;====
; Adjusts the buffered tilemap xScroll value by a given number of pixels. If
; this results in a new column needing to be drawn it sets flags in RAM
; indicating whether the left or right column needs re-writing. You can
; interpret these flags using tilemap.ifColScroll.
;
; The scroll value won't apply until you call tilemap.writeScrollRegisters
;
; @in   a   the number of x pixels to adjust. Positive values scroll right in
;           the game world (shifting the tiles left). Negative values scroll
;           left (shifting the tiles right)
;====
.macro "tilemap.adjustXPixels"
    \@_\.:
    utils.clobbers "af" "bc" "hl"
        call tilemap._adjustXPixels
    utils.clobbers.end
.endm

;====
; See tilemap.adjustXPixels
;
; @in   a   the number of x pixels to adjust. Positive values scroll right in
;           the game world (shifting the tiles left). Negative values scroll
;           left (shifting the tiles right)
;====
.section "tilemap._adjustXPixels" free
    tilemap._adjustXPixels:
        or a                                ; analyse A
        jp z, _noColumnScroll               ; if adjust is zero, no scroll needed
        ld hl, tilemap.ram.xScrollBuffer    ; point to xScrollBuffer
        ld b, (hl)                          ; load current xScrollBuffer into B
        jp p, _movingRight                  ; jump if xAdjust is positive

        _movingLeft:
            ; Adjust xScrollBuffer
            add a, b                        ; add xAdjust to xScrollBuffer
            ld (hl), a                      ; store new xScrollBuffer

            ; Detect if left column needs updating (if upper 5 bits change)
            xor b                           ; compare bits with old value in B
            and %11111000                   ; zero all but upper 5 bits
            jp z, _noColumnScroll           ; jp if zero (upper 5 bits were the same)

            ; Left column needs scrolling
            inc hl                          ; point to flags
            ld a, (hl)                      ; load flags into A
            or tilemap.SCROLL_LEFT_SET_MASK ; set left scroll flags
            ld (hl), a                      ; store flags
            ret

        _movingRight:
            ; Adjust xScrollBuffer
            add a, b                        ; add xAdjust to xScrollBuffer
            ld (hl), a                      ; store new xScrollBuffer

            ; Detect if right column needs updating (if upper 5 bits change)
            xor b                           ; compare bits with old value in B
            and %11111000                   ; zero all but upper 5 bits
            jp z, _noColumnScroll           ; jp if zero (upper 5 bits were the same)

            ; Right column needs scrolling
            inc hl                          ; point to flags
            ld a, (hl)                      ; load flags into A
            and tilemap.SCROLL_X_RESET_MASK ; reset previous x scroll flags
            or tilemap.SCROLL_RIGHT_SET_MASK; set right scroll flag
            ld (hl), a                      ; store flags
            ret

    ; No scroll needed
    _noColumnScroll:
        ld hl, tilemap.ram.flags
        ld a, tilemap.SCROLL_X_RESET_MASK
        and (hl)            ; reset X scroll flags with mask
        ld (hl), a          ; update flags
        ret
.ends
