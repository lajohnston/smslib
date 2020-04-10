;====
; Constants
;====
; VDP ports
.define smslib.VDP_COMMAND_PORT $bf
.define smslib.VDP_DATA_PORT $be

.ifndef "smslib.outiBlock.MAX"
    .define smslib.outiBlock.MAX 1024
.endif

;====
; Outputs the given number of bytes using the fast OUTI block method
;
; @in     c   the port to write to
; @in     hl  the address to copy from
; @in     bytes   the number of bytes to output
;====
.section "smslib.outiBlock" free
    .rept smslib.outiBlock.MAX
        outi
    .endr

    smslib.outiBlock:
        ret
.ends

.macro "smslib.outiBlock" args bytes
    call (smslib.outiBlock - bytes * 2)
.endm

;====
; Outputs the given data to VRAM using the fast OUTI block method
;
; @in     hl      the source address to copy from
; @in     dest    the destination address in VRAM to write to
; @in     bytes   the number of bytes to write
;
; @clobs af, bc, hl
;====
.macro "smslib.fastVramWrite" args dest bytes
    ; Output low byte of address to VDP
    ld a, <dest
    out (smslib.VDP_COMMAND_PORT), a

    ; Output high byte of address to VDP, ORed with %01000000 to issue write command
    ld a, >dest | %01000000
    out (smslib.VDP_COMMAND_PORT), a

    ; Port to write to
    ld c, smslib.VDP_DATA_PORT

    ; Output
    smslib.outiBlock bytes
.endm

;====
; Sets the VRAM write address. The next byte sent to the data port will be
; written to this address
;
; @in    address    the VRAM write address
; @clobs af
;====
.macro "smslib.setVdpWrite" args address
    ; Output low byte to VDP
    ld a, <address
    out (vdp.COMMAND_PORT), a

    ; Output high byte to VDP, ORed with $40 (01000000) to issue write command
    ld a, >address | $40
    out (vdp.COMMAND_PORT), a
.endm
