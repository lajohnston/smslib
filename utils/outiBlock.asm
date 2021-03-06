;====
; Manages a big block of OUTI instructions, the fastest way to output data to
; the VDP
;====

.define utils.outiBlock 1

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
.ifndef "utils.outiBlock.size"
    .define utils.outiBlock.size 1024
.endif

;==
; The maximum number of fast inline OUTIs that can be generated before falling
; back to calling the OUTI block. Inline OUTIs save a call and return
; (24-cycles) but take up 2-bytes per OUTI
;==
.ifndef "utils.outiBlock.maxInlineOutis"
    .define utils.outiBlock.maxInlineOutis 4
.endif

;==
; The minimum address the outi block can be placed in ROM. The block will be
; placed somewhere above this address, allowing it to align itself to provide
; optimisations
;==
.ifndef "utils.outiBlock.minAddress"
    .define utils.outiBlock.minAddress 160    ; allow room for interrupts
.endif

;====
; Constants
;====

; Number of OUTI instructions in the OUTI block; AND with $ffff to get floor
.define utils.outiBlock.SIZE_BYTES utils.outiBlock.size * 2

; Address of the last OUTI instruction int he block - ensure it falls on an $xxFF offset
.define utils.outiBlock.LAST_OUTI_ADDRESS ((((utils.outiBlock.minAddress + utils.outiBlock.SIZE_BYTES) / 256) + 1) & $FFFF) * 256 - 1

;====
; Procedures
;====

;====
; Creates a block of OUTI instructions to provide the fastest means of
; outputting data to the VDP. Generate calls to this using the
; utils.outiBlock.send macro
;
; @in     c     the port to write to
; @in     hl    the address to copy from
;====
.orga utils.outiBlock.LAST_OUTI_ADDRESS - utils.outiBlock.SIZE_BYTES + 2
.section "utils.outiBlock.block" force
    .rept utils.outiBlock.size - 1
        outi
    .endr

    utils.outiBlock.lastOuti:
        outi

    utils.outiBlock.block:
        ret
.ends

;====
; Send data using the fast OUTI block
;
; @in   bytes   the number of bytes to output
; @in   c       the output port
; @in   hl      the source data address
;====
.macro "utils.outiBlock.send" args bytes
    ; Transfer chunks if data exceeds outi block size
    .rept bytes / utils.outiBlock.size
        call utils.outiBlock.block - utils.outiBlock.SIZE_BYTES
    .endr

    ; Transfer remaining bytes
    .if bytes <= utils.outiBlock.maxInlineOutis
        ; Generate inline outis
        .rept bytes
            outi
        .endr
    .else
        call utils.outiBlock.block - (bytes # utils.outiBlock.size) * 2
    .endif
.endm

;====
; OUTI between 1-128 bytes
;
; @in   b   the number of bytes to write. Must be greater than 0 and <= 128
; @in   hl  the address of the source data
;====
.section "utils.outiBlock.sendUpTo128Bytes" free
    utils.outiBlock.sendUpTo128Bytes:
        ; Address of last OUTI instruction
        ld d, >(utils.outiBlock.lastOuti)         ; high-byte address of last outi
        ld a, <(utils.outiBlock.lastOuti)         ; load low-byte address of last outi

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
.macro "utils.outiBlock.sendSlice" args arrayAddr itemSize count offset
    ld hl, arrayAddr + (offset * itemSize)
    utils.outiBlock.send (count * itemSize)
.endm
