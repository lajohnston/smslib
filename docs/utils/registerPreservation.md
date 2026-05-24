# Register preservation (utils.clobbers, utils.preserve, utils.restore)

It costs 21 cycles to `push/pop` registers to the stack to preserve them (and 28 for IX, IY), which can quickly add up if several pairs need to be preserved.

As the library prioritises efficiency, by default the routines won't preserve any registers and will leave the caller to remember to preserve only the ones it cares about. While efficient, this can be bug prone and still lead to waste if the caller pushes a register pair the routine doesn't even clobber.

These utility modules provide a system for efficiently preserving Z80 register states between macro calls, ensuring only the needed registers are preserved.

The system works as follows:

1. Macros declare which registers they clobber using [utils.clobbers](#utilsclobbers)
2. Code calling these macros can declare which registers it is actually relying on to be preserved, using [utils.preserve](#utilspreserve) or by enabling [Automatic register preservation](#automatic-register-preservation)
3. When a macro is about to clobber a register pair the caller cares about, it will ensure it is preserved on the stack. If the caller doesn't care about a register pair it will let it be clobbered, saving cycles.

## Automatic register preservation

If you aren't prioritising maximum performance you can set the `utils.registers.AUTO_PRESERVE` setting to ensure the libraries automatically preserve any registers they clobber.

```asm
.redefine utils.registers.AUTO_PRESERVE 0 ; deactivate (default)
.redefine utils.registers.AUTO_PRESERVE 1 ; activate
```

You can still wrap individual macro calls with [utils.preserve](#utilspreserve) to ensure only specific registers are preserved for that call.

## utils.preserve

Callers that rely on register states to be preserved can wrap the macro invokation with `utils.preserve` and `utils.restore`. This is referred to as a 'preserve scope'.

The macro being called specifies which registers it will clobber using [utils.clobbers](#utilsclobbers). The two will work together to ensure only the required registers are preserved.

```asm
.macro "myMacro"
    ld bc, $bcbc
    ld de, $dede

    registers.preserve "bc", "de"
        macroThatClobsThings        ; might push BC or DE
        otherMacroThatClobsThings   ; might push BC or DE (if not already pushed)
    utils.restore                   ; pops BC/DE if they were pushed

    ; BC will still be $bcde
    ; DE will still be $dede
.endm
```

Acceptable arguments are (case-insensitive):

- Main registers: `"af"`, `"bc"`, `"de"`, `"hl"`, `"ix"`, `"iy"`, `"i"`
- Shadow registers: `"af'"`, `"bc'"`, `"de'"`, `"hl'"`

As each clobber scope is encountered in the macro chain, it will now be aware which registers the caller wishes to preserve and so preserves any that match. If the call passes through multiple nested clobber scopes that clobber the same particular register, only the first-encountered (outer) scope will preserve the register rather than it being preserved multiple times.

Calling `utils.preserve` with no arguments will default to ensuring all registers that get clobbered are preserved.

Like clobber scopes, it's possible to nest preserve scopes. Inner scopes are aware of what registers the outer scope needs preserving.

`utils.preserve` can be used within a `section` that calls macros.

### Gotchas and known issues

Routines don't mark their return values as clobbered, as these values are intentional. These will have to be preserved manually outside the code block. Below, `palette.setIndex` returns the VDP port in C, ready to write to, and so BC would need to be preserved manually.

```asm
push bc ; preserve BC manually

utils.preserve
    palette.setIndex 0                  ; sets/returns C
    palette.writeBytes ram.color 1
utils.restore                           ; won't restore BC

pop bc  ; restore BC ourselves
```

Your manual push and pop instructions should be outside the `utils.preserve`/`utils.restore` scope so as to not interrupt the preservation order.

## utils.clobbers

Macros that clobber registers can utilise `utils.clobbers` and `utils.clobbers.end` in place of the `push`/`pop` calls they would normally make. This is referred to as a 'clobber scope'.

The internal libraries utilise this module to mark which registers they clobber. You can also use it in your own code but it can get quite complicated so you don't necessarily need to.

```asm
.macro "normal way"
    push af
    push de
    push hl
        ...
    pop hl  ; pop in reverse order
    pop de
    pop af
.endm

.macro "with utils/clobbers.asm"
    utils.clobbers "af" "de" "hl"
        ... ; code
    utils.clobbers.end
.endm
```

Acceptable arguments are (case-insensitive):

- Main registers: `"af"`, `"bc"`, `"de"`, `"hl"`, `"ix"`, `"iy"`, `"i"`
- Shadow registers: `"af'"`, `"bc'"`, `"de'"`, `"hl'"`

Clobber scopes can be nested within one another, so when calling other macros it's possible for these to define their own clobber scopes. If you need to call a macro that isn't clobber scope aware, the calling macro will need to take responsibility to wrap the call.

Using `utils.clobbers` directly inside `sections` could produce unpredictable results as they won't be aware of the context they're `call`ed in. You'll instead just need to wrap the `call` in its own macro that defines the clobber scopes.

```asm
.section "someRoutine" free
    someRoutine:
        ... ; code that clobbers af and hl
        ret
.ends

.macro "someRoutine"    ; WLA-DX allows you to use the same name if you wish
    utils.clobbers "af" "hl"
        call someRoutine
    utils.clobbers.end
.endm
```

### utils.clobbers.withBranching

If the macro produces code with multiple exit points (i.e. jumps that skip over `utils.clobbers.end`), you can use `utils.clobbers.withBranching` with special jump instructions to ensure relevant registers are restored before the jumps. If there are no registers to restore these will just perform their vanilla jump instructions.

Care should be taken to ensure the jumps don't jump outside of multiple clobber scopes and preserve scopes. The macros don't know where the jump locations are so aren't able to determine if multiple scopes should be restored.

```asm
utils.clobbers.withBranching "af"
    utils.clobbers.endBranch            ; call before unconditional jp or jr

    utils.clobbers.end.jrz, _someLabel  ; if Z, restore and jr
    utils.clobbers.end.jrnz _someLabel  ; if NZ, restore and jr
    utils.clobbers.end.jrc, _someLabel  ; if carry set, restore and jr
    utils.clobbers.end.jrnc, _someLabel ; if carry is reset, restore and jr

    utils.clobbers.end.jpz  _someLabel  ; if Z, restore and jp
    utils.clobbers.end.jpnz _someLabel  ; if NZ, restore and jp
    utils.clobbers.end.jpc  _someLabel  ; if carry, restore and jp
    utils.clobbers.end.jpnc _someLabel  ; if not carry, restore and jp
    utils.clobbers.end.jppe _someLabel  ; if parity/overflow, restore and jp
    utils.clobbers.end.jppo _someLabel  ; if not parity/overflow, restore and jp
    utils.clobbers.end.jpm  _someLabel  ; if sign, restore and jp
    utils.clobbers.end.jpp  _someLabel  ; if not sign, restore and jp

    utils.clobbers.end.retc             ; return if carry set
    utils.clobbers.end.retnc            ; return if carry is reset
utils.clobbers.end
```

In most cases `utils.clobbers.withBranching` results in the same performance as `utils.clobbers`, but in certain edge cases it knows to opt out of some optimisations to ensure there isn't a mismatch between the registers that get pushed and popped onto the stack.

If using conditional jumps, `utils.clobbers.end` is still needed to mark the end of the clobber scope and restore the registers if the jumps don't occur.

#### utils.clobbers.closeBranch

If the restore instructions aren't needed (i.e. there's an unconditional jump at the end that will always jump over it) you can use `utils.clobbers.closeBranch` to close off the branching clobber scope without generating the uneeded restore instructions.

```asm
utils.clobbers.withBranching "af"
    utils.clobbers.endBranch    ; restore registers
    jp somewhere                ; unconditional jump
utils.clobbers.closeBranch      ; close off branching clobber scope without restoring
```
