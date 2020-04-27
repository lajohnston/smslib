;====
; VDP
;====

.define vdp.COMMAND_PORT $bf   ; write (issue command to vdp)
.define vdp.STATUS_PORT  $bf   ; read (returns vdp status)
.define vdp.DATA_PORT    $be

.define vdp.cram.write $c000
.define vdp.color.address $c000


;====
; The following must be set in your project
;====

.define vdp.address.patterns $4000
.define vdp.address.palette $c000
.define vdp.address.sprites $3f00
.define vdp.address.tilemap $3800

;====
; General
;====

;====
; Sets the VRAM write address. The next byte sent to the data port will be
; written to this address
;
; @in    address    the VRAM write address
; @clobs af
;====
.macro "vdp.setWriteAddress.inline" args address
    ; Output low byte to VDP
    ld a, <address
    out (vdp.COMMAND_PORT), a

    ; Output high byte to VDP, ORed with $40 (01000000) to issue write command
    ld a, >address | $40
    out (vdp.COMMAND_PORT), a
.endm

;====
; Sends a byte to the data port. If the write command and
; address has been set then this byte will be written to the address
; @in    value   the value to send to the data port
;====
.macro "vdp.writeByte" args value
    ld a, value
    out (vdp.DATA_PORT), a
.endm

;====
; Sends 2 bytes to the data port. If the write command and
; address has been set then this byte will be written to the address
; @in    value   the value to send to the data port
;====
.macro "vdp.writeWord" args word
    vdp.writeByte (<word)
    vdp.writeByte (>word)
.endm

;====
; Copies data to the VDP VRAM
; @in  hl    address of the first byte to write
; @in  bc    length of the data to write, in bytes
; @clobs a, hl, bc
; @author maxim
;====
.section "vdp.writeBlock" free
    vdp.writeBlock:
        -:
            ld a, (hl)              ; Load byte into a
            out (vdp.DATA_PORT), a ; Output data to vdp, which auto increments
            inc hl                  ; Point to next byte
            dec bc                  ; Dec byte counter
            ld a, b
            or c
        jr nz,-
    ret
.ends

;====
; Zeroes all the VRAM
; @clobs af, bc
;====
.section "vdp.clearVram" free
    vdp.clearVram:
        ; 1. Set VRAM write address to $0000
        vdp.setWriteAddress.inline 0

        ; 2. Output 16KB of zeroes
        ld bc, $4000     ; Counter for 16KB of VRAM
        -:
            xor a
            out (vdp.DATA_PORT), a ; Output to VRAM address, which is auto-incremented after each write
            dec bc
            ld a,b
            or c
        jr nz,-
    ret
.ends

; Macro alias for call vdp.clearVram
.macro "vdp.clearVram"
    call vdp.clearVram
.endm
