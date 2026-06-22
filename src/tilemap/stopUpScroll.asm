;====
; When tilemap.ifRowScroll indicates an up scroll, but you detect this new row
; will be out of bounds of the tilemap, call this to cap the y pixel scrolling
; to the top of the current in-bounds row. Further calls to tilemap.ifRowScroll
; will indicate that no row scroll is required and thus prevent rendering an
; invalid row.
;
; Note: This should be called before calling tilemap.calculateScroll
;====
.macro "tilemap.stopUpRowScroll"
    \@_\.:
    utils.clobbers "af"
        call tilemap._stopUpRowScroll
    utils.clobbers.end
.endm

.section "tilemap._stopUpRowScroll" free
    tilemap._stopUpRowScroll:
        ; Reset UP scroll flag
        ld a, (tilemap.ram.flags)           ; load flags
        and tilemap.SCROLL_Y_RESET_MASK     ; reset Y scroll flags
        ld (tilemap.ram.flags), a           ; store updated flags

        ; Round yScrollBuffer to top of previous row
        ld a, (tilemap.ram.yScrollBuffer)   ; load current value
        add 8                               ; add 8px to go back down one row

        ; Ensure value hasn't gone out of 0-223 range
        cp tilemap.Y_PIXELS
        jp c, +
            ; Sub screen height to bring back into range (i.e. 224 becomes 0)
            sub tilemap.Y_PIXELS
        +:

        and %11111000                       ; round to top pixel of that row
        ld (tilemap.ram.yScrollBuffer), a   ; update yScrollBuffer

        ret
.ends
