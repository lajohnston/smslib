;====
; Copies pattern ref bytes to VRAM until a terminator byte is reached
;
; @in   terminator      value that signifies the end of the data
; @in   dataAddr        address of the first byte of ASCII data
; @in   [attributes]    tile attributes to use for all the tiles (see tile
;                       attribute options at top). Defaults to 0
;====
.macro "tilemap.writeBytesUntil" args terminator dataAddr attributes
    utils.assert.range terminator 0 255 "\.: terminator should be a byte value"
    utils.assert.label dataAddr "\.: dataAddr should be a label"

    utils.clobbers "af", "bc", "de", "hl"
        ld d, terminator
        ld hl, dataAddr

        .ifdef attributes
            utils.assert.range attributes 0 255 "\.: attributes should be a byte value"
            ld b, attributes
        .else
            ld b, 0
        .endif

        call tilemap._writeBytesUntil
    utils.clobbers.end
.endm

;====
; Reads pattern ref bytes and writes to the tilemap until a terminator byte is
; reached.
;
; @in   hl  address of the data to write
; @in   b   tile attributes to use for all the tiles
; @in   c   the data port to write to
; @in   d   the terminator byte value
;====
.section "tilemap._writeBytesUntil" free
    tilemap._writeBytesUntil:
        ld a, (hl)                          ; read byte
        cp d                                ; compare value with terminator
        ret z                               ; return if terminator byte found
        out (utils.vdpCommand.DATA_PORT), a ; write pattern ref
        ld a, b                             ; load attributes
        out (utils.vdpCommand.DATA_PORT), a ; write attributes
        inc hl                              ; next char
        jp tilemap._writeBytesUntil         ; repeat
.ends
