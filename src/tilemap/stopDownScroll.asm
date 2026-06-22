;====
; When tilemap.ifRowScroll indicates a down scroll, but you detect this new row
; will be out of bounds of the tilemap, call this to cap the y pixel scrolling
; to the top of the current in-bounds row. Further calls to tilemap.ifRowScroll
; will indicate that no row scroll is required and thus prevent rendering an
; invalid row.
;
; Note: This should be called before calling tilemap.calculateScroll
;====
.macro "tilemap.stopDownRowScroll"
    \@_\.:
    utils.clobbers "af"
        call tilemap._stopDownRowScroll
    utils.clobbers.end
.endm

.section "tilemap._stopDownRowScroll" free
    tilemap._stopDownRowScroll:
        ; Reset Y scroll flags
        ld a, (tilemap.ram.flags)           ; load flags
        and tilemap.SCROLL_Y_RESET_MASK     ; reset Y scroll flags
        ld (tilemap.ram.flags), a           ; store updated flags

        ; Adjust yScrollBuffer to point to bottom pixel of previous row
        ld a, (tilemap.ram.yScrollBuffer)   ; load current value
        sub 8                               ; sub 8px to go back up one row

        ; Ensure value hasn't gone out of 0-223 range
        jp nc, +
            ; Value dropped below 0 - bring back into range
            add tilemap.Y_PIXELS            ; -1 becomes 223
        +:

        ; Round yScrollBuffer to bottom pixel of the row
        or %00000111                        ; set bits 0-2
        ld (tilemap.ram.yScrollBuffer), a   ; store result

        ret
.ends