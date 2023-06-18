.define utils.ram

;====
; Constants
;====
.define utils.ram.BYTES $2000

;====
; Dependencies
;====
.ifndef utils.assert
    .include "utils/assert.asm"
.endif

;====
; Sets a utils.ram.SLOT value to either the user-defined smslib.RAM_SLOT value or
; the mapper-defined slot (mapper.RAM_SLOT). This allows modules to define RAM
; sections using the correct slot without being coupled to the mapper or global
; variable
;
; @fail if value cannot be determined
;====
.ifdef smslib.RAM_SLOT
    .redefine utils.ram.SLOT smslib.RAM_SLOT
.else
    .ifdef mapper.RAM_SLOT
        .redefine utils.ram.SLOT mapper.RAM_SLOT
    .else
        .print "\.: Cannot determine which RAM slot to use:"
        .print " Either .define an smslib.RAM_SLOT value or include an "
        .print " smslib mapper before including the other modules"
        .print "\n\n"
        .fail
    .endif
.endif

;====
; Fills a portion of RAM with the given value
;
; @in   bytes       the number of bytes to fill
; @in   address|hl  the first byte to fill
; @in   value|a     the value to set the bytes to
;====
.macro "utils.ram.fill" args bytes address value
    utils.assert.range NARGS, 1, 3, "utils/ram.asm \.: Invalid number of arguments"
    utils.assert.range bytes, 1, utils.ram.BYTES, "utils/ram.asm \.: Invalid bytes argument"

    ; Assert address argument is valid
    .ifdef address
        utils.assert.label address, "utils/ram.asm \.: Invalid address argument"
    .endif

    ; Set A to value, if given
    .ifdef value
        utils.assert.range value, 0, 255, "utils/ram.asm \.: Invalid value argument"

        .if value == 0
            xor a       ; set A to 0
        .else
            ld a, value
        .endif
    .endif

    ; Check number of bytes to fill
    .if bytes <= 8
        ;===
        ; There aren't many bytes to fill
        ;===
        .ifdef address
            ; If address is a constant, just use ld (nn), a
            ; Fastest method, but uses 3-bytes of code per byte
            .repeat bytes index index
                ld (address + index), a
            .endr
        .else
            ; If address is a variable in HL, use ld (hl), a
            .repeat bytes index index
                ld (hl), a

                ; Increment HL if there are more bytes to go
                .if index < bytes - 1
                    inc hl
                .endif
            .endr
        .endif
    .else
        ;===
        ; There are lots of bytes to fill
        ;===

        .ifdef address
            ; Set HL to address and DE to address + 1
            ld hl, address
            ld de, address + 1
        .else
            ; Address is a variable in HL. Set DE to HL + 1
            ld d, h
            ld e, l
            inc de
        .endif

        ld (hl), a          ; set first byte
        ld bc, bytes - 1    ; set BC to bytes, minus the first one we set

        ; Copy byte n to n + 1 until done
        ldir
    .endif
.endm
