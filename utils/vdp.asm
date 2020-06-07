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
; The number of OUTI instructions in the OUTI block. This block is used to
; provide a fast means of outputting data to the VDP but requires a chunk of ROM
; space.
;
; Each OUTI transfers 1-byte. Lower values may mean transfers require multiple
; calls to this block, each taking up 24-cycles. Each OUTI takes 2-bytes of ROM.
;==
.ifndef "utils.vdp.outiBlockCount"
    .define utils.vdp.outiBlockCount 256
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
; The minimum address the outi block can be placed in ROM. The block will be
; placed somewhere above this address, allowing it to align itself to provide
; optimisations
;====
.ifndef "utils.vdp.outiBlockMinAddress"
    .define utils.vdp.outiBlockMinAddress 160    ; allow room for interrupts
.endif

;====
; Constants
;====

; VDP ports
.define utils.vdp.VDP_COMMAND_PORT $bf
.define utils.vdp.VDP_DATA_PORT $be

; Number of OUTI instructions in the OUTI block; AND with $ffff to get floor
.define utils.vdp.OUTI_BLOCK_SIZE utils.vdp.outiBlockCount * 2

;====
; Creates a block of OUTI instructions to provide the fastest means of
; outputting data to the VDP. Generate calls to this using the
; utils.vdp.callOutiBlock macro
;
; @in     c     the port to write to
; @in     hl    the address to copy from
;====

; Ensure last outi address falls on an $xxFF offset
.define utils.vdp.LAST_OUTI_ADDRESS ((((utils.vdp.outiBlockMinAddress + utils.vdp.OUTI_BLOCK_SIZE) / 256) + 1) & $FFFF) * 256 - 1
.orga utils.vdp.LAST_OUTI_ADDRESS - utils.vdp.OUTI_BLOCK_SIZE + 2
.section "utils.vdp.outiBlock" force
    .rept utils.vdp.outiBlockCount - 1
        outi
    .endr

    utils.vdp.lastOuti:
        outi

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
    .rept bytes / utils.vdp.outiBlockCount
        call utils.vdp.outiBlock - utils.vdp.outiBlockCount * 2
    .endr

    ; Transfer remaining bytes
    .if bytes <= utils.vdp.maxInlineOutis
        ; Generate inline outis
        .rept bytes
            outi
        .endr
    .else
        call utils.vdp.outiBlock - (bytes # utils.vdp.outiBlockCount) * 2
    .endif
.endm

;====
; OUTI between 1-128 bytes
;
; @in   b   the number of bytes to write. Must be greater than 0 and <= 128
; @in   hl  the address of the source data
;====
.section "utils.vdp.sendUpTo128Bytes" free
    utils.vdp.sendUpTo128Bytes:
        ; Address of last OUTI instruction
        ld d, >(utils.vdp.lastOuti)         ; high-byte address of last outi
        ld a, <(utils.vdp.lastOuti)         ; load low-byte address of last outi

        ; Subtract additional bytes required
        dec b                               ; make 0-based (0 = 1, 127 = 128)
        sub b                               ; subtract bytes
        sub b                               ; subtract again (1 outi = 2 bytes)
        ld e, a                             ; set low-byte of address

        ; Push address to stack then 'return' to it
        ; ret in outi block will return to original caller
        push de                             ; push address to stack
        ret                                 ; 'return' to address in stack
.ends

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
; @in   address     the VRAM write address
; @in   [setPort]   if 1 (the default) then the c register will be loaded with
;                   the VDP data. Set to 0 if the port is already set (saves 7
;                   cycles)
;====
.macro "utils.vdp.prepWrite" args address setPort
    ; Output low byte to VDP
    ld a, <address
    out (utils.vdp.VDP_COMMAND_PORT), a

    ; Output high byte to VDP
    ; OR with $40 (%01000000) to set 6th bit and issue write command
    ld a, >address | $40
    out (utils.vdp.VDP_COMMAND_PORT), a

    ; Port to write to
    .ifndef setPort
        .redefine setPort 1
    .endif

    .if setPort == 1
        ld c, utils.vdp.VDP_DATA_PORT
    .endif
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
        jr nz, -
    ret
.ends

; Macro alias for call utils.vdp.clearVram
.macro "utils.vdp.clearVram"
    call utils.vdp.clearVram
.endm
