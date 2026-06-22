;====
; Jumps to the relevant label if a row scroll is needed after a call to
; tilemap.adjustYPixels. Must be called with either 3 arguments (up, down, else)
; or just else alone
;
; @in   up      (optional) continue to this label if top row needs loading
; @in   down    (optional) jump to this label if the bottom row needs loading
; @in   else    jump to this label if no columns need loading
;====
.macro "tilemap.ifRowScroll" args up, down, else
    .if NARGS == 1
        utils.clobbers.withBranching "af"
            ; Only one argument passed ('else' label)
            ld a, (tilemap.ram.flags)   ; load flags
            rrca                        ; set C to bit 0
            utils.clobbers.end.jpnc \1  ; jp to else if no row scroll (bit 0 was 0)
            ; ...otherwise continue
        utils.clobbers.end
    .elif NARGS == 3
        utils.clobbers.withBranching "af"
            ld a, (tilemap.ram.flags)   ; load flags
            rrca                        ; set C to bit 0
            utils.clobbers.end.jpnc else; no row to scroll (bit 0 was 0)

            ; Check down scroll flag
            rrca                        ; set C to what was bit 1
            utils.clobbers.end.jpc down ; jp if scrolling down (bit 1 was set)
            ; ...otherwise continue to 'up' label
        utils.clobbers.end
    .else
        .print "\ntilemap.ifRowScroll requires 1 or 3 arguments (up/down/else, or just else alone)\n\n"
        .fail
    .endif
.endm
