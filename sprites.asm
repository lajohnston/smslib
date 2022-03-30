;====
; Sprite Buffer
; Manages a sprite table buffer in RAM and transfers it to VRAM
;====
.define sprites.ENABLED 1

;====
; Settings
;
; Define these before including this file if you wish to override the defaults
;====

; The maximum screen y coordinate a sprite can be. Defaults to 192
.ifndef sprites.maxYPos
    .define sprites.maxYPos 192
.endif

; The sprite table's address in VRAM. Defaults to $3f00
.ifndef sprites.vramAddress
    .define sprites.vramAddress $3f00
.endif

; The high byte of the RAM address to place the sprite buffer. The low byte is
; always set to $3F to allow for optimisations
.ifndef sprites.bufferAddressHigh
    .define sprites.bufferAddressHigh $C0
.endif

;====
; Dependencies
;====
.include "./utils/ram.asm"

.ifndef utils.vdp
    .include "utils/vdp.asm"
.endif

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

;====
; Constants and variables
;====
.define sprites.BUFFER_ADDRESS (sprites.bufferAddressHigh * 256) + $3F
.define sprites.GROUP_TERMINATOR 255  ; terminates list of sprites.Sprite instances
.define sprites.Y_TERMINATOR $D0
.define sprites.MAX_SPRITES 64

; If 1 a batch is in progress, otherwise it is 0
.define sprites.batchInProgress 0

;====
; Sprite buffer
;
; An instance should be placed in RAM at a $xx3F offset and named
; 'sprites.ram.buffer'
;====
.struct "sprites.Buffer"
    nextSlot:       DSB 1   ; the low byte address of the next free y slot
    yPos:           DSB 64  ; screen yPos for each of the 64 sprites
    xPosAndPattern: DSB 128 ; { 1 byte xPos, 1 byte pattern } * 64 sprites
.endst

;====
; RAM
;====

;====
; The offset of $40 is required to make use of performance optimisations. This
; technique is described by user gvx32 in:
; https://www.smspower.org/forums/15794-AFewHintsOnCodingAMediumLargeSizedGameUsingWLADX
;====
.ramsection "sprites.ram.buffer" bank 0 slot utils.ram.SLOT orga sprites.BUFFER_ADDRESS force
    sprites.ram.buffer: instanceof sprites.Buffer
.ends

;====
; Represents a single sprite. If using sprites.addGroup, more than one can be
; defined in a list terminated with a sprites.GROUP_TERMINATOR byte
;====
.struct "sprites.Sprite"
    relativeX:  db
    relativeY:  db
    pattern:    db
.endst

;====
; Define data for a sprites.Sprite instance
;
; @in   pattern     the pattern number
; @in   relativeX   the relativeX position
; @in   relativeY   the relativeY position
;====
.macro "sprites.sprite" args pattern, relX, relY
    .db relX relY pattern
.endm

;====
; Marks the start of a group of sprites. Doesn't currently do anything but is
; provided for semantics
;====
.macro "sprites.startGroup"
    ; do nothing - macro provided for semantics
.endm

;====
; Marks the end of a group of sprites
;====
.macro "sprites.endGroup"
    .db sprites.GROUP_TERMINATOR
.endm

;====
; Loads the next available sprite slot (y position) into de
;
; @out  de  the address of the next available slot
;====
.macro "sprites.getNextSlot"
    ld de, sprites.ram.buffer + sprites.Buffer.nextSlot
    ld a, (de)
    ld e, a
.endm

;====
; Stores the current slot
;
; @in   de  the address of the current slot (y position)
;====
.macro "sprites._storeNextSlot"
    ; Store next slot
    ld a, e
    ld de, sprites.ram.buffer + sprites.Buffer.nextSlot
    ld (de), a
.endm

;====
; Adds a sprite to the buffer
;====
.section "sprites.add" free
    ;====
    ; Add sprite to the next available slot
    ;
    ; @in  a  screen yPos
    ; @in  b  screen xPos
    ; @in  c  pattern number
    ;====
    sprites.addToNextSlot:
        ; Retrieve next slot
        ld iyl, a               ; preserve yPos
        sprites.getNextSlot
        ld a, iyl               ; restore yPos
                                ; continue to sprites.add

    ;====
    ; Set a sprite in the currently selected slot
    ;
    ; @in  de pointer to next available y slot in sprite buffer
    ; @in  a  screen yPos
    ; @in  b  screen xPos
    ; @in  c  pattern number
    ;====
    sprites.add:
        ; Set ypos
        ld (de), a

        ; xPos
        rlc e   ; Switch to xPos (e = e * 2; works because of $xx40 offset)
        ld a, b
        ld (de), a

        ; Pattern
        inc e
        ld a, c
        ld (de), a

        ; Restore de to point back to yPos
        rr e    ; (e - 1) / 2
        inc e   ; point to next free slot
        ret
.ends

;====
; Add a sprite to the buffer
;
; @in  a  screen yPos
; @in  b  screen xPos
; @in  c  pattern number
;
; @in  de (optional)    pointer to next available slot (yPos) in sprite buffer
;                       Only required if a batch is in progress
;====
.macro "sprites.add"
    .if sprites.batchInProgress == 1
        call sprites.add
    .else
        call sprites.addToNextSlot
        sprites._storeNextSlot
    .endif
.endm

;====
; Starts a 'batch' of sprites. If adding multiple sprites and sprite groups it
; is more efficient to wrap the multiple calls in sprites.startBatch and
; sprites.endBatch; This ensures the nextSlot value is only read and updated
; once rather than for each sprite or spriteGroup
;====
.macro "sprites.startBatch"
    .ifeq sprites.batchInProgress 1
        .print "Warning: sprites.startBatch called but batch already in progress."
        .print " Ensure you also call sprites.endBatch\n\n"
    .endif

    .redefine sprites.batchInProgress 1
    sprites.getNextSlot
.endm

;====
; Ends a sprite batch
;====
.macro "sprites.endBatch"
    .ifeq sprites.batchInProgress 0
        .print "Warning: sprites.endBatch called but no batch is in progress"
    .else
        .redefine sprites.batchInProgress 0
        sprites._storeNextSlot
    .endif
.endm

;====
; Initialises a sprite buffer in RAM
;====
.macro "sprites.init"
    ; Set nextSlot to slot 0
    ld a, <(sprites.ram.buffer) + sprites.Buffer.yPos   ; low byte of slot 0
    ld de, sprites.ram.buffer + sprites.Buffer.nextSlot ; point to 'nextSlot'
    ld (de), a                                          ; store low byte
.endm

;====
; Reset sprite buffer back to default. Alias for sprites.init
;====
.macro "sprites.reset"
    sprites.init
.endm

;====
; Copies the sprite buffer from RAM to VRAM. This should be performed while the
; display is off or during VBlank
;====
.section "sprites.copyToVram"
    sprites.copyToVram:
        ; Load number of slots occupied
        ld hl, sprites.ram.buffer + sprites.Buffer.nextSlot ; nextSlot address
        ld a, (hl)  ; read nextSlot value
        sub $40     ; remove table offset to get sprite count
        push iy     ; preserve iy
        ld iyh, a   ; preserve counter in iyh

        ; Set VDP write address to y positions
        utils.vdp.prepWrite sprites.vramAddress

        ; Copy y positions to VRAM
        jp z, _noSprites                ; jp if no sprites
        ld b, iyh                       ; load size into b
        inc l                           ; point to y positions in buffer
        call utils.outiBlock.sendUpTo128Bytes ; send data

        ; Output sprite terminator at end of y positions
        ld a, iyh                       ; load counter into a
        cp sprites.MAX_SPRITES          ; compare with max sprites
        jp nc, +                        ; skip if counter == max sprites
            ld a, sprites.Y_TERMINATOR  ; load y terminator into a
            out (c), a                  ; output y terminator
        +:

        ; Point to x positions in VRAM and buffer
        utils.vdp.prepWrite (sprites.vramAddress + 128) 0           ; vram
        ld l, <(sprites.ram.buffer) + sprites.Buffer.xPosAndPattern ; buffer

        ; Copy x positions and patterns from buffer to VRAM
        ld b, iyh                       ; restore sprite count
        pop iy                          ; restore iy
        rlc b                           ; double to get xPos + pattern
        jp utils.outiBlock.sendUpTo128Bytes   ; send bytes, then ret

    ; No sprites in buffer - cap table with sprite terminator then return
    ; VRAM address must be set
    _noSprites:
        ld a, sprites.Y_TERMINATOR      ; load y terminator into a
        out (c), a                      ; output y terminator
        pop iy                          ; restore iy
        ret
.ends

;====
; Alias for sprites.copyToVram
;====
.macro "sprites.copyToVram"
    call sprites.copyToVram
.endm

;====
; Adds a group of sprites relative to an anchor position. Sprites within the
; group that fall off-screen are not added.
;
; Limitation: Once the anchorX position falls off screen the entire group will
; disappear, meaning the group cannot move smoothly off the left edge of the
; screen. This can be partially obscured by setting the VDP registers to hide
; the left column
;====
.section "sprites.addGroup"
    ;====
    ; Gets the next free sprite slot and adds a sprite group from there onwards
    ;
    ; @in   b   anchor x position (left-most)
    ; @in   c   anchor y position (top-most)
    ; @in   hl  pointer to sprites.Sprite instances terminated by
    ;           sprites.GROUP_TERMINATOR
    ;
    ; @out  de  next free sprite slot
    ;====
    sprites.addGroupFromNextSlot:
        sprites.getNextSlot
        jp sprites.addGroup

    ;====
    ; Add a group of sprites from the currently selected slot
    ;
    ; @in   b   anchor x position (left-most)
    ; @in   c   anchor y position (top-most)
    ; @in   de  pointer to next free sprite slot
    ; @in   hl  pointer to sprites.Sprite instances terminated by
    ;           sprites.GROUP_TERMINATOR
    ;
    ; @out  de  next free sprite slot
    ;====
    _xOffScreen:
        inc hl  ; point to relY
    _yOffScreen:
        inc hl  ; point to pattern
    _nextSprite:
        inc hl  ; point to next item

    sprites.addGroup:
        ld a, (hl)          ; load relX
        cp sprites.GROUP_TERMINATOR
        ret z               ; end of group

        ; Add relative x
        add a, b            ; relX + anchorX
        jp c, _xOffScreen   ; off screen; next sprite
        ld ixh, a           ; store result x for later

        ; Add relative y
        inc hl              ; point to relY
        ld a, (hl)          ; load relY
        add a, c            ; relY + anchorY
        cp sprites.maxYPos  ; compare with max y allowed
        jp nc, _yOffScreen  ; off screen; next sprite

        ; Output sprite to sprite buffer
        ld (de), a          ; set sprite y in buffer
        rlc e               ; point to sprite x; works because of $xx40 offset
        ld a, ixh           ; restore x
        ld (de), a          ; set sprite x in buffer
        inc hl              ; point to pattern number in group
        inc e               ; point to pattern number in buffer
        ld a, (hl)          ; load pattern number
        ld (de), a          ; set pattern number in buffer
        rr e                ; return to y in buffer
        inc e               ; point to next sprite slot in buffer
        jp _nextSprite
.ends

;====
; Macro alias for sprites.addGroup
;====
.macro "sprites.addGroup"
    .if sprites.batchInProgress == 1
        call sprites.addGroup
    .else
        call sprites.addGroupFromNextSlot
        sprites._storeNextSlot
    .endif
.endm
