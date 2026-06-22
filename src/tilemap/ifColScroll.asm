;====
; Jumps to the relevant label if a column scroll is needed after a call to
; tilemap.adjustXPixels. Must be called with either 3 arguments (left, right, else)
; or just else alone
;
; @in   left    (optional) continue to this label if left column needs loading
; @in   right   (optional) jump to this label if the right column needs loading
; @in   else    jump to this label if no columns need loading
;====
.macro "tilemap.ifColScroll" args left, right, else
    \@_\.:

    .if NARGS == 1
        ; Only one argument passed ('else' label)
        utils.clobbers.withBranching "af"
            ld a, (tilemap.ram.flags)       ; load flags
            rlca                            ; set carry to 7th bit
            utils.clobbers.end.jpnc \1      ; jp to else if no col to scroll
        utils.clobbers.end
        ; ...otherwise continue
    .elif NARGS == 3
        utils.clobbers.withBranching "af"
            ; 3 arguments passed (left, right, else)
            ld a, (tilemap.ram.flags)       ; load flags
            rlca                            ; set C to 7th bit
            utils.clobbers.end.jpnc else    ; bit 7 was 0 - no col scroll

            ; Check right scroll flag
            rlca                            ; set C to what was 6th bit
            utils.clobbers.end.jpnc right   ; bit 6 was 0 - scrolling right
            ; ...otherwise continue to left label
        utils.clobbers.end
    .else
        .print "\ntilemap.ifColScroll requires 1 or 3 arguments (left/right/else, or just else alone)\n\n"
        .fail
    .endif
.endm
