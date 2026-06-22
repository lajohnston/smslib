;====
; Update the scroll registers and write the necessary col/row data to VRAM.
; This should be called when the display is off or during VBlank
;====
.macro "tilemap.writeScrollBuffers"
    utils.clobbers "af" "bc" "de" "hl" "iy"
        call tilemap.writeScrollBuffers
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
; be a sequential list of tiles starting with top of the column visible on screen
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
    ; Prep the call to the address stored in tilemap.ram.colWriteCall, which
    ; points to an iteration of tilemap._writeColumn
    ;===

    ; Set E to column address bits
    ld e, a

    ; Set D to column bits ORed with 128, as required by tilemap._writeColumn
    or 128  ; OR A by 128 to combine bits
    ld d, a ; set D to value

    ; Set B to bytes to write (tilemap.COL_SIZE_BYTES), and C to utils.vdpCommand.DATA_PORT
    ld bc, (tilemap.COL_SIZE_BYTES * 256) + utils.vdpCommand.DATA_PORT

    ; Set HL to the tile data to write
    .ifdef dataAddr
        ld hl, dataAddr
    .else
        ld hl, tilemap.ram.colBuffer
    .endif

    ; Call (tilemap.ram.colWriteCall); This points to an iteration of
    ; tilemap._writeColumn
    ld iy, (tilemap.ram.colWriteCall)
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
.section "tilemap.writeScrollBuffers" free
    tilemap.writeScrollBuffers:
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
                utils.outiBlock.writeUpTo128Bytes

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
                utils.outiBlock.writeUpTo128BytesThenReturn
        +:

        ret
.ends
