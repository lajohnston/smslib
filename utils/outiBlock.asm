;====
; Manages a big block of OUTI instructions, the fastest way to write data to
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
; provide a fast means of writing data to the VDP but requires a chunk of ROM
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
; Dependencies
;====
.ifndef utils.assert
    .include "utils/assert.asm"
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
; writing data to the VDP. Generate calls to this using the
; utils.outiBlock.write macro
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
; Write data to VRAM using the fast OUTI block
;
; @in   bytes   the number of bytes to write
; @in   c       the output port
; @in   hl      the source data address
;====
.macro "utils.outiBlock.write" args bytes
    utils.assert.range bytes 1 16384 "outiBlock.asm \.: Invalid bytes argument"

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
; @in   c   the port to output the data to
; @in   hl  the address of the source data
;====
.section "utils.outiBlock.writeUpTo128Bytes" free
    utils.outiBlock.writeUpTo128Bytes:
        ; Address of last OUTI instruction
        ld iyh, >(utils.outiBlock.lastOuti) ; high-byte address of last outi
        ld a, <(utils.outiBlock.lastOuti)   ; load low-byte address of last outi

        ; Subtract outi instructions required
        dec b       ; exclude the byte the last outi will write
        sub b       ; subtract remaining bytes
        sub b       ; subtract again (1 outi = 2 bytes)
        ld iyl, a   ; set low-byte of address in IY

        ; JP to the outi address in IY; ret in outi block will return to
        ; the original caller
        jp (iy)
.ends

;====
; Alias for utils.outiBlock.writeUpTo128Bytes
;====
.macro "utils.outiBlock.writeUpTo128Bytes"
    call utils.outiBlock.writeUpTo128Bytes
.endm

;====
; Writes elements from an array of data to VRAM using OUTI instructions
;
; @in   dataAddress the address of the data to transfer
; @in   elementSize the size of each array element in bytes
; @in   count       the number of elements to transfer (1-based)
; @in   offset      the first item in the array to copy (0-based)
;====
.macro "utils.outiBlock.writeSlice" args dataAddress elementSize count offset
    ld hl, dataAddress + (offset * elementSize)
    utils.outiBlock.write (count * elementSize)
.endm
