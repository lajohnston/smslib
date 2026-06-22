;====
; Returns if no row scroll is needed, otherwise jumps to the relevant
; 'up' or 'down' label depending on the row scroll direction
;
; @in   up      if scrolling up, will continue to this label
; @in   down    if scrolling down, will jump to this label
;====
.macro "tilemap.ifRowScrollElseRet" args up, down
    utils.assert.equals NARGS 2 "\. requires 2 arguments (up and down)"

    utils.clobbers.withBranching "af"
        ld a, (tilemap.ram.flags)   ; load flags
        rrca                        ; set C to bit 0
        utils.clobbers.end.retnc    ; return if no row to scroll

        ; Check down scroll flag
        rrca                        ; set C to what was bit 1
        utils.clobbers.end.jpc down ; jp if down scroll (bit 1 was set)
        ; ...otherwise continue to 'up' label
    utils.clobbers.end
.endm
