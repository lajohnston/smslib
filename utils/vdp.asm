;====
; Utilities for writing data to the VDP
;====

.define utils.vdp 1

;====
; Settings
;
; Define these before including smslib modules if you wish to override the
; defaults
;====

;==
; OUTI block size in bytes. This block is used to provide a fast means of
; outputting data to the VDP but requires a chunk of ROM space. Lower values
; may mean transfers require multiple calls to this block, each taking
; up 24-cycles. Each OUTI takes 2-bytes, so 512 allows 256 bytes of data to be
; transferred in one call
;==
.ifndef "utils.vdp.outiBlockSize"
    .define utils.vdp.outiBlockSize 512
.endif

;==
; The maximum number of fast inline OUTIs that can be generated before falling
; back to calling the OUTI block. Inline OUTIs save a call and return
; (24-cycles) but take up 2-bytes per OUTI
;==
.ifndef "utils.vdp.maxInlineOutis"
    .define utils.vdp.maxInlineOutis 4
.endif

;====
; Constants
;====

; VDP ports
.define utils.vdp.VDP_COMMAND_PORT $bf
.define utils.vdp.VDP_DATA_PORT $be

; Number of OUTI instructions in the OUTI block; AND with $ffff to get floor
.define utils.vdp.OUTI_BLOCK_INSTRUCTIONS (utils.vdp.outiBlockSize / 2) & $ffff

;====
; Creates a block of OUTI instructions to provide the fastest means of
; outputting data to the VDP. Generate calls to this using the
; utils.vdp.callOutiBlock macro
;
; @in     c     the port to write to
; @in     hl    the address to copy from
;====
.section "utils.vdp.outiBlock" free
    .rept utils.vdp.OUTI_BLOCK_INSTRUCTIONS
        outi
    .endr

    utils.vdp.outiBlock:
        ret
.ends

;====
; Call the OUTI block to output the given number of bytes
;
; @in   bytes   the number of bytes to output
; @in   c       the output port
; @in   hl      the source data address
;====
.macro "utils.vdp.callOutiBlock" args bytes
    ; Transfer chunks if data exceeds outi block size
    .rept bytes / utils.vdp.OUTI_BLOCK_INSTRUCTIONS
        call utils.vdp.outiBlock - utils.vdp.OUTI_BLOCK_INSTRUCTIONS * 2
    .endr

    ; Transfer remaining bytes
    .if bytes <= utils.vdp.maxInlineOutis
        ; Generate inline outis
        .rept bytes
            outi
        .endr
    .else
        call utils.vdp.outiBlock - (bytes # utils.vdp.OUTI_BLOCK_INSTRUCTIONS) * 2
    .endif
.endm

;====
; Copies an array of data using OUTI instructions
;
; @in   arrayAddr   the address of the data to transfer
; @in   itemSize    the size of each array item in bytes
; @in   count       the number of items to transfer (1-based)
; @in   offset      the first item in the array to copy (0-based)
;====
.macro "utils.vdp.outputArray" args arrayAddr itemSize count offset
    ld hl, arrayAddr + (offset * itemSize)
    utils.vdp.callOutiBlock (count * itemSize)
.endm

;====
; Prepares the VDP to write to the given VRAM write address
;
; @in    address    the VRAM write address
;====
.macro "utils.vdp.prepWrite" args address
    ; Output low byte to VDP
    ld a, <address
    out (utils.vdp.VDP_COMMAND_PORT), a

    ; Output high byte to VDP, ORed with $40 (01000000) to issue write command
    ld a, >address | $40
    out (utils.vdp.VDP_COMMAND_PORT), a

    ; Port to write to
    ld c, utils.vdp.VDP_DATA_PORT
.endm

;====
; Zeroes all the VRAM
;====
.section "utils.vdp.clearVram" free
    utils.vdp.clearVram:
        ; 1. Set VRAM write address to $0000
        utils.vdp.prepWrite 0

        ; 2. Output 16KB of zeroes
        ld bc, $4000     ; Counter for 16KB of VRAM
        -:
            xor a
            out (utils.vdp.VDP_DATA_PORT), a ; Output to VRAM address, which is auto-incremented after each write
            dec bc
            ld a, b
            or c
        jr nz,-
    ret
.ends

; Macro alias for call utils.vdp.clearVram
.macro "utils.vdp.clearVram"
    call utils.vdp.clearVram
.endm
