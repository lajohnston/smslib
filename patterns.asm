;====
; Manages patterns (graphic tiles) in the VDP
;
; Provided for example purposes to get you started. For an actual game you
; would want to compress pattern data using an algorithm such as zx7 or aPLib
; and use the appropriate lib to decompress and send to VRAM
;====

;====
; Settings
;====

; Pattern address in VRAM
.ifndef patterns.address
    .define patterns.address $0000
.endif

.define patterns.SLOT_SIZE 32

;====
; Loads patterns into VRAM.
;
; Each pattern is an 8x8 image of 4-bit pixels making a total of 32-bytes.
;
; Each pixel is a 4-bit color palette reference. This can reference slots 0-15
; or 16-31 depending on the context where the pattern is used - sprites use
; slots 16-31 whereas background tiles in the tilemap contain a bit that
; determines which to use. If used as a sprite, color 0 is used as the
; transparent color.
;
; Pixels are encoded in bitplanes so the bits of each are strewn across 2-bytes
;
; Example:
;
; Pixel 1 = 0110
; Pixel 2 = 0011
; Pixel 3 = 1010
; Pixel 4 = 0001
;
; Pixel No.     1234 1234 1234 1234
; Bits          0010 1000 1110 0101
;
; @in  dataAddress   the address of the first byte of data
; @in  size          the size of the data block, in bytes
; @in  patternSlot  the first pattern slot
;====
.macro "patterns.load" args dataAddr slots offset
    .ifndef offset
        smslib.outputArray dataAddr patterns.SLOT_SIZE slots 0
    .else
        smslib.outputArray dataAddr patterns.SLOT_SIZE slots offset
    .endif
.endm

;====
; Set the current pattern slot ready to load data into
; @in   slot    the slot number (0-512)
;====
.macro "patterns.setSlot" args slot
    smslib.prepVdpWrite (patterns.address + (slot * 32))
.endm
