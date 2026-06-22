;====
; Writes bytes of data representing tile pattern refs. The patterns will all
; share the same attributes
;
; @in   address         the address of the data to write
; @in   count           the number of bytes to write
; @in   attributes      (optional) the attributes to use for each tile
;                       See tile attribute options at top. Defaults to $00
;====
.macro "tilemap.writeBytes" args address count attributes
    utils.assert.label address "\.: Address should be a label"
    utils.assert.range count 0 tilemap.TILES "\.: Count should be between 0 and {tilemap.TILES}"

    utils.clobbers "af", "hl", "bc"
        ld hl, address
        ld b,  count

        .ifdef attributes
            ld c, attributes
        .else
            ld c, 0
        .endif

        call tilemap._writeBytes
    utils.clobbers.end
.endm

;====
; Write bytes of data representing tile pattern refs
;
; @in   hl  the address of the data to write
; @in   b   the number of bytes to write
; @in   c   tile attributes to use for all the tiles (see tile
;           attribute options at top)
;====
.section "tilemap._writeBytes" free
    _nextByte:
        inc hl                                  ; next byte

    tilemap._writeBytes:
        ld a, (hl)                              ; read byte
        out (utils.vdpCommand.DATA_PORT), a     ; write pattern ref
        ld a, c                                 ; load attributes
        out (utils.vdpCommand.DATA_PORT), a     ; write attributes
        djnz _nextByte                          ; repeat until b = 0
        ret
.ends