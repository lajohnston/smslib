;====
; When tilemap.ifColScroll indicates a right scroll, but you detect this new row
; will be out of bounds of the tilemap, call this to cap the x pixel scrolling
; to the right edge of the current in-bounds column. Further calls to
; tilemap.ifColScroll will indicate that no column scroll is required and thus
; prevent rendering an invalid column.
;
; Note: This should be called before calling tilemap.calculateScroll
;====
.macro "tilemap.stopRightColScroll"
    \@_\.:
    utils.clobbers "af"
        call tilemap._stopRightColScroll
    utils.clobbers.end
.endm

.section "tilemap._stopRightColScroll" free
    tilemap._stopRightColScroll:
        ; Reset column scroll flags
        ld a, (tilemap.ram.flags)           ; load flags
        and tilemap.SCROLL_X_RESET_MASK     ; reset x scroll flags
        ld (tilemap.ram.flags), a           ; store updated flags

        ; Round xScrollBuffer to right of previous column
        ld a, (tilemap.ram.xScrollBuffer)   ; load current scroll value
        sub 8                               ; go left one column
        or %00000111                        ; set to right-most pixel of the col
        ld (tilemap.ram.xScrollBuffer), a   ; update xScrollBuffer

        ret
.ends
