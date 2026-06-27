;====
; Update the scroll registers and write the necessary col/row data to VRAM.
; This should be called when the display is off or during VBlank
;====
.macro "tilemap.writeScrollBuffers"
    utils.clobbers "af" "bc" "de" "hl" "iy"
        call tilemap._writeScrollBuffers
    utils.clobbers.end
.endm

;====
; Sends the buffered scroll register values to the VDP. This should be called
; when the display is off or during a V or H interrupt
;====
.macro "tilemap._writeScrollRegisters"
    utils.clobbers "af"
        ld a, (tilemap.ram.xScrollBuffer)
        neg
        utils.vdpCommand.setRegister tilemap.SCROLL_X_REGISTER

        ld a, (tilemap.ram.yScrollBuffer)
        utils.vdpCommand.setRegister tilemap.SCROLL_Y_REGISTER
    utils.clobbers.end
.endm

;====
; Write tile data to the scrolling column in VRAM, if required. The data should
; be a sequential list of tiles starting with the top tile of the column visible
; on screen
;
; @in   dataAddr    (optional) pointer to the sequential tile data (top of the
;                   column). Defaults to the internal column buffer
;====
.macro "tilemap._writeScrollCol" isolated args dataAddr
    ; Calculate the column bits for the write address
    ; If no col scroll needed, skip to _continue
    tilemap.ifColScroll, _left, _right, _continue
        _left:
            ld a, (tilemap.ram.xScrollBuffer)   ; load X scroll
            add 8                               ; go right 1 column to correct
            and %11111000                       ; floor value to nearest 8
            rrca                                ; divide by 2
            rrca                                ; divide by 2 again (4)
            ; We would need to divide by 2 again (8 total) then multiply by 2
            ; as there are 2 bytes per tile, but these operations cancel each
            ; other out and so aren't required
            jp +
        _right:
            ld a, (tilemap.ram.xScrollBuffer)   ; load X scroll
            and %11111000                       ; floor value to nearest 8
            rrca                                ; divide by 2
            rrca                                ; divide by 2 again (4)
            ; We would need to divide by 2 again (8 total) then multiply by 2
            ; as there are 2 bytes per tile, but these operations cancel each
            ; other out and so aren't required
    +:

    ;===
    ; Lookup the tilemap._writeColumn index
    ;===

    ; Set E to column address bits
    ld e, a

    ; Set D to column bits ORed with 128, as required by tilemap._writeColumn
    or 128  ; OR A by 128 to combine bits
    ld d, a ; set D to value

    ; Set HL to tilemap._writeColumnLookup + offset in A
    ld hl, tilemap._writeColumnLookup
    ld a, (tilemap.ram.colWriteIndex)   ; load row offset into A
    add l           ; add L to row offset in A
    ld l, a         ; store low byte in L

    ; Load (HL) into B and A
    ld b, (hl)      ; load low byte into B
    inc l           ; point to high byte
    ld a, (hl)      ; load high byte into A

    ; Transfer to IY
    ld iyh, a       ; set high byte of IY
    ld iyl, b       ; set low byte of IY

    ; Set HL to the tile data to write
    .ifdef dataAddr
        ld hl, dataAddr
    .else
        ld hl, tilemap.ram.colBuffer
    .endif

    ; Set B to bytes to write (tilemap.COL_SIZE_BYTES), and C to utils.vdpCommand.DATA_PORT
    ld bc, (tilemap.COL_SIZE_BYTES * 256) + utils.vdpCommand.DATA_PORT

    call tilemap._callIY

    _continue:
.endm

;====
; Calls the address stored in IY
;
; @in   iy  the address to call
;====
.section "tilemap._callIY" free
    tilemap._callIY:
        jp (iy)
.ends

;====
; Sets the VRAM write address to the row that requires updating. If no row needs
; scrolling, the write address will be set to the last row scrolled
;
; @out  VRAM write address  write address for the row (column 0)
; @out  c                   VDP data port
;====
.macro "tilemap._setRowScrollIndex"
    ld hl, (tilemap.ram.vramRowWrite)
    utils.vdpCommand.setFromHl utils.vdpCommand.WRITE_VRAM
    ld c, utils.vdpCommand.DATA_PORT
.endm

;====
; See tilemap.writeScrollBuffers macro alias
;====
.section "tilemap._writeScrollBuffers" free
    tilemap._writeScrollBuffers:
        ; Set scroll registers
        tilemap._writeScrollRegisters

        ; Write column tiles from buffer to VRAM if required
        tilemap._writeScrollCol

        ; Detect whether the row buffer should be flushed
        tilemap.ifRowScroll +
            ; Set VRAM address to the scrolling row
            ; Set C to the VDP output port
            tilemap._setRowScrollIndex

            ;===
            ; First write
            ; Set B to bytes to write minus floor(xScroll / 4)
            ; Set HL to end of the buffer minus bytes to write
            ;===
            _firstWrite:
                ld h, >tilemap.ram.rowBuffer    ; set H to high byte of rowBuffer
                ld a, (tilemap.ram.xScrollBuffer)
                sub tilemap.X_OFFSET    ; cancel X offset
                rrca                    ; divide by 2
                rrca                    ; divide by 2 (4 total)
                and %00111110           ; clean value; now equals col * 2 bytes
                ld e, a                 ; preserve result in E
                jp z, _secondWrite      ; skip if the are no bytes in first write
                ld b, a                 ; set B to bytes to write

                ; Set A to the last byte of the buffer
                ld a, <(tilemap.ram.rowBuffer + tilemap.ROW_SIZE_BYTES)

                ; Subtract bytes we need to write
                sub b

                ; Point HL to end of buffer minus bytes
                ld l, a

                ; Copy bytes from buffer to VDP
                utils.vram.writeUpTo128Bytes

            ;===
            ; Second write
            ; Set B to ROW_SIZE_BYTES minus bytes written in first write
            ; Set HL to start of rowBuffer
            ;===
            _secondWrite:
                ; Set HL to start of rowBuffer; No need to update H as the data
                ; is aligned
                ld l, <(tilemap.ram.rowBuffer)  ; set L to low byte of rowBuffer

                ; Bytes to write
                ld a, tilemap.ROW_SIZE_BYTES
                sub e       ; subtract bytes written in first write

                ; Write bytes then return to caller
                ld b, a     ; set B to bytes to write
                utils.vram.writeUpTo128BytesThenReturn
        +:

        ret
.ends

;====
; Lookup table for the loop iterations in tilemap._writeColumn
; Usage: load HL with tilemap._writeColumnLookup then add row * 2 to L; HL will
; then point to the address to call in the loop
;=====
.section "tilemap._writeColumnLookup" free bitwindow 8
    tilemap._writeColumnLookup:
        ; The offset to the current tilemap._writeColumn iteration
        .redefine tilemap._writeColumnLookup_currentOffset 0

        ; Iterate over each potential row, starting from 0
        .repeat tilemap.ROWS index rowNumber
            ; Set address of the row iteration in tilemap._writeColumn
            .dw tilemap._writeColumn + tilemap._writeColumnLookup_currentOffset

            ; Update offset to next iteration
            .if rowNumber # 2 == 0
                ; Every second iteration uses additional optimisations, so we
                ; only need to increase the offset by 12 bytes
                .redefine tilemap._writeColumnLookup_currentOffset tilemap._writeColumnLookup_currentOffset + 12
            .else
                ; Increase offset by 14 bytes
                .redefine tilemap._writeColumnLookup_currentOffset tilemap._writeColumnLookup_currentOffset + 14
            .endif
        .endr
.ends

;====
; Unrolled loop of column tile writes. Call one of the addresses stored in the
; tilemap._writeColumnLookup lookup table to start from a given row. The loop
; will wrap back to 0 after the 28th tile is written and continue until all
; bytes are written
;
; @in   hl  pointer to sequential tile data
; @in   b   bytes to write (number of rows * 2)
; @in   d   column number * 2 ORed with 128
; @in   e   column number * 2
;====
.section "tilemap._writeColumn" free
    tilemap._writeColumn:
        .repeat tilemap.ROWS index rowNumber
            ; Calculate write address for column 0
            .redefine tilemap._writeColumn_writeAddress ($4000 | tilemap.VRAM_ADDRESS) + (rowNumber * tilemap.COLS * tilemap.TILE_SIZE_BYTES)
            .redefine tilemap._writeColumn_writeAddressHigh >tilemap._writeColumn_writeAddress
            .redefine tilemap._writeColumn_writeAddressLow <tilemap._writeColumn_writeAddress

            ; Calculate VRAM low byte write address (0, 64, 128, 192)
            .if tilemap._writeColumn_writeAddressLow == 0
                ; Row address low byte is 0; Just set A to column address
                ld a, e ; set A to column address
            .elif tilemap._writeColumn_writeAddressLow == 128
                ; Row address low byte is 128; This value (and col address) is cached in D
                ld a, d
            .else
                ; Set A to low address
                ld a, tilemap._writeColumn_writeAddressLow

                ; Set column address bits
                or e
            .endif

            ; Set VRAM low byte write address
            out (utils.vdpCommand.COMMAND_PORT), a

            ; Set VRAM high byte write address
            ld a,  tilemap._writeColumn_writeAddressHigh; set A to high address
            out (utils.vdpCommand.COMMAND_PORT), a  ; send to VDP

            ; Write tile
            outi    ; pattern ref
            outi    ; tile attributes
            ret z   ; return if no more tiles to write (B = 0)
        .endr

        jp tilemap._writeColumn  ; continue from row 0
.ends
