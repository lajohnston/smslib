;====
; SMSLib common functionality
;
; Include this file along with any of the additional modules you require.
; See README.md for more instructions
;====

;====
; Settings
;
; Define these before '.include "smslib.asm"'' if you wish to override
; the defaults
;====

; OUTI block size in bytes. This block is used to provide a fast means of
; outputting data to the VDP but requires a chunk of ROM space. Lower values
; may mean transfers require multiple calls to this block, each taking
; up 24-cycles. Each OUTI takes 2-bytes, so 512 allows 256 bytes of data to be
; transferred in one call
.ifndef "smslib.outiBlockSize"
    .define smslib.outiBlockSize 512
.endif

; The maximum number of fast inline OUTIs that can be generated before falling
; back to calling the OUTI block. Inline OUTIs save a call and return
; (24-cycles) but take up 2-bytes per OUTI
.ifndef "smslib.maxInlineOutis"
    .define smslib.maxInlineOutis 4
.endif

;====
; Constants
;====
; VDP ports
.define smslib.VDP_COMMAND_PORT $bf
.define smslib.VDP_DATA_PORT $be

; Number of OUTI instructions in the OUTI block; AND with $ffff to get floor
.define smslib.OUTI_BLOCK_INSTRUCTIONS (smslib.outiBlockSize / 2) & $ffff

;====
; Initialises the system. Should be called at orga 0.
;
; Clears vram
; If a mapper is being used it will initialise the paging registers
; If vdpreg is being used it will initialise the VDP registers
;
; @in   then    (optional) label to jump to when complete
;====
.macro "smslib.init" args then
    di              ; disable interrupts
    im 1            ; interrupt mode 1
    ld sp, $dff0    ; set stack pointer

    ; initialise paging registers
    .ifdef mapper
        mapper.init
    .endif

    ; initialise vdp registers
    .ifdef vdpreg
        vdpreg.init
    .endif

    ; initialise sprite buffer
    .ifdef sprites
        sprites.init
    .endif

    call smslib.clearVram

    .ifdef then
        jp then         ; jump to init section
    .endif
.endm

;====
; Creates a block of OUTI instructions to provide the fastest means of
; outputting data to the VDP. Generate calls to this using the
; smslib.callOutiBlock macro
;
; @in     c     the port to write to
; @in     hl    the address to copy from
;====
.section "smslib.outiBlock" free
    .rept smslib.OUTI_BLOCK_INSTRUCTIONS
        outi
    .endr

    smslib.outiBlock:
        ret
.ends

;====
; Call the OUTI block to output the given number of bytes
;
; @in   bytes   the number of bytes to output
; @in   c       the output port
; @in   hl      the source data address
;====
.macro "smslib.callOutiBlock" args bytes
    ; Transfer chunks if data exceeds outi block size
    .rept bytes / smslib.OUTI_BLOCK_INSTRUCTIONS
        call smslib.outiBlock - smslib.OUTI_BLOCK_INSTRUCTIONS * 2
    .endr

    ; Transfer remaining bytes
    .if bytes <= smslib.maxInlineOutis
        ; Generate inline outis
        .rept bytes
            outi
        .endr
    .else
        call smslib.outiBlock - (bytes # smslib.OUTI_BLOCK_INSTRUCTIONS) * 2
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
.macro "smslib.outputArray" args arrayAddr itemSize count offset
    ld hl, arrayAddr + (offset * itemSize)
    smslib.callOutiBlock (count * itemSize)
.endm

;====
; Prepares the VDP to write to the given VRAM write address
;
; @in    address    the VRAM write address
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

;====
; Zeroes all the VRAM
;====
.section "smslib.clearVram" free
    smslib.clearVram:
        ; 1. Set VRAM write address to $0000
        smslib.prepVdpWrite 0

        ; 2. Output 16KB of zeroes
        ld bc, $4000     ; Counter for 16KB of VRAM
        -:
            xor a
            out (smslib.VDP_DATA_PORT), a ; Output to VRAM address, which is auto-incremented after each write
            dec bc
            ld a, b
            or c
        jr nz,-
    ret
.ends

; Macro alias for call smslib.clearVram
.macro "smslib.clearVram"
    call smslib.clearVram
.endm