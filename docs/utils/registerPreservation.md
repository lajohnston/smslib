# Register preservation (utils.clobbers, utils.preserve, utils.restore)

These utility modules provide a system for efficiently preserving Z80 register states between macro calls, ensuring only the needed registers are preserved.

It's common practice for routines to `push` and `pop` the registers they clobber onto the stack to prevent unexpected side-effects for the caller. These `push`/`pop`s instruction pairs take 21-28 cycles each and so can unfortunately add up to a large percentage of the routine's total cost, particularly if sub-routines they rely on also `push`/`pop` the same values. Routines are also less free to utilise registers as temporary locations, knowing they will have to preserve those as well.

In many cases the caller doesn't actually care about the values being preserved, so another approach is to place responsibility on the caller to preserve what registers it relies on. Each routine is then free to optimse itself and make the full use of all the registers, knowing the caller takes responsibility for preserving only what it needs. The caller can also potentially be refactored to not have to preserve these registers at all.

The later approach can take some getting used to and still contains some inefficiency, as the caller might preserve registers that don't even get clobbered. Worse, the caller might have knowledge that certain registers aren't clobbered and so not preserve them, only for a later update to start clobbing them and suddenly cause hard-to-debug problems.

The macros in `utils.registers.asm` provide a middle-ground to mitigate the problems above. They allow macro routines to state which registers they clobber, in-lieu of the `push` and `pop` calls. Callers can in turn state which registers they care about preserving, and at assemble-time the macros will work together to only preserve registers the caller requests AND that are getting clobbered by the macros. The minimum required registers will therefore be preserved and will automatically update as implementations change.

## Automatic registers preseveration

To automatically preserve all registers by default, consider setting the `utils.registers.AUTO_PRESERVE` value. When a clobber scope is encountered it will then automatically preserve all registers that get clobbered.

```asm
.redefine utils.registers.AUTO_PRESERVE 0 ; deactivate (default)
.redefine utils.registers.AUTO_PRESERVE 1 ; activate
```

You can opt-out of this on a per-call basis using `utils.preserve` to create more-specific preserve scopes for particular calls.

## utils.clobbers, utils.clobbers.end

Macros that clobber registers can utilise `utils.clobbers` and `utils.clobbers.end` in place of the `push`/`pop` calls they would normally make. This is referred to as a 'clobber scope'.

```asm
.macro "normal way"
    push af
    push de
        ...
    pop de  ; pop in reverse order
    pop af
.endm

.macro "with registers.asm"
    utils.clobbers "AF" "DE"
        ...
    utils.clobbers.end
.endm
```

Acceptable arguments are:

- Main registers: `"af"`, `"bc"`, `"de"`, `"hl"`, `"ix"`, `"iy"`, `"i"` (case-insensitive)
- Shadow registers: `"af'"`, `"bc'"`, `"de'"`, `"hl'"`

Clob scopes can be nested within one another, so when calling other macros it's possible for these to define their own clobber scopes. If you need to call a macro that isn't clobber scope aware, the calling macro will need to take responsibility to wrap the call.

Utilising these macros within `sections` will produce unpredictable results as they won't be aware of the context they're `call`ed in. You'll instead just need to wrap the `call` in it's own macro that defines the clobber scopes.

```asm
.section "someRoutine" free
    someRoutine:
        ... ; code that clobbers af and hl
        ret
.ends

.macro "someRoutine"    ; WLA-DX allows you to use the same name if you wish
    registers.clobbers "af" "hl"
        call someRoutine
    utils.clobbers.end
.endm
```

## utils.preserve, utils.restore

Callers that rely on register states to be preserved can wrap the macro invokation with `utils.preserve` and `utils.restore`. This is referred to as a 'preserve scope'.

```asm
.macro "myMacro"
    ld bc, $1234

    registers.preserve "bc"
        macroThatClobsThings
    utils.restore

    ; bc will still be $1234
.endm
```

Acceptable arguments are:

- Main registers: `"af"`, `"bc"`, `"de"`, `"hl"`, `"ix"`, `"iy"`, `"i"` (case-insensitive)
- Shadow registers: `"af'"`, `"bc'"`, `"de'"`, `"hl'"`

As each clobber scope is encountered in the macro chain, it will now be aware which registers you wish to preserve and so preserve any that match. If the call passes through multiple nested clobber scopes that clobber the same particular register, only the first-encountered (outer) scope will preserve the register rather than it being preserved multiple times.

Calling `utils.preserve` with no arguments will default to ensuring all registers that get clobbered are preserved.

Like clobber scopes, it's possible to nest preserve scopes. Inner scopes are aware of what registers the outer scope needs preserving.
