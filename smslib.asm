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

.macro "smslib.callOutiBlock" args bytes
    call (smslib.outiBlock - bytes * 2)
.endm

;====
; Outputs the given data to VRAM using the fast OUTI block method
;
; @in   dataStart
; @in   dataEnd
;
; @clobs af, bc, hl
;====
.macro "smslib.copyToVdp" args dataStart dataEnd
    ld hl, dataStart
    smslib.callOutiBlock (dataEnd - dataStart)
.endm

;====
; Prepares the VDP to write to given VRAM write address.
;
; @in    address    the VRAM write address
; @clobs af
;====
.macro "smslib.prepVdpWrite" args address
    ; Output low byte to VDP
    ld a, <address
    out (smslib.VDP_COMMAND_PORT), a

    ; Output high byte to VDP, ORed with $40 (01000000) to issue write command
    ld a, >address | $40
    out (smslib.VDP_COMMAND_PORT), a

    ; Port to write to
    ld c, smslib.VDP_DATA_PORT
.endm
