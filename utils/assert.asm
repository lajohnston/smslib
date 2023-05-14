;====
; Checks values match expections at assemble-time and fails if they are not met
;====
.define utils.assert 1

;====
; Print a given value to the terminal
;
; @in   value   the value to print (a string, number, label, immediate value
;               or pending calculation)
;====
.macro "utils.assert.printValue" args value
    .if \?1 == ARG_STRING
        .print "<string> \"", \1, "\""
    .elif \?1 == ARG_LABEL
        .print "<label> " \1
    .elif \?1 == ARG_NUMBER
        .print DEC \1, " ($", HEX \1, ")"
    .elif \?1 == ARG_IMMEDIATE
        .print "<immediate>"
    .elif \?1 == ARG_PENDING_CALCULATION
        .print "<pending calculation>"
    .else
        .print "<unknown>"
    .endif
.endm

;====
; Print an error message to the terminal and stop compilation
;
; @in   message     the main message to print
; @in   expected    the value that was expected
; @in   received    the value that didn't match an expection
;====
.macro "utils.assert.fail" args message expected received
    .print message, "\n"

    .print "    Expected: ", expected, "\n"

    .print "    Received: "
    utils.assert.printValue received
    .print "\n"

    .fail
.endm

;====
; Assert the given value matches the expected value, otherwise fail
;
; @in   value       the actual value
; @in   expected    the expected value
; @in   message     the message to print if the expectation is not met
;====
.macro "utils.assert.equals" args value, expected, message
    .if value != expected
        utils.assert.fail message expected value
    .endif
.endm

;====
; Assert the given value is an immediate value, otherwise fail
;
; @in   value       the actual value
; @in   message     the message to print if the expectation is not met
;====
.macro "utils.assert.immediate" args value message
    .if \?1 != ARG_IMMEDIATE
        utils.assert.fail message "<immediate>" value
    .endif
.endm


;====
; Assert the given value is a label, otherwise fail
;
; @in   value       the actual value
; @in   message     the message to print if the expectation is not met
;====
.macro "utils.assert.label" args value message
    .if \?1 != ARG_LABEL
        utils.assert.fail message "<label>" value
    .endif
.endm

;====
; Assert the given value is a number, otherwise fail
;
; @in   value       the actual value
; @in   message     the message to print if the expectation is not met
;====
.macro "utils.assert.number" args value message
    .if \?1 != ARG_NUMBER
        utils.assert.fail message "<number>" value
    .endif
.endm

;====
; Assert the given value is a number within the given range, otherwise fail
;
; @in   value       the actual value
; @in   min         the minimum allowed value
; @in   max         the maximum allowed value
; @in   message     the message to print if the expectation is not met
;====
.macro "utils.assert.range" args value min max message
    .if \?1 != ARG_NUMBER
        utils.assert.fail message "number between \2 to \3" value
    .endif

    .if value < min || value > max
        utils.assert.fail message "number between \2 to \3" value
    .endif
.endm

;====
; Assert the given value is a string, otherwise fail
;
; @in   value       the actual value
; @in   message     the message to print if the expectation is not met
;====
.macro "utils.assert.string" args value message
    .if \?1 != ARG_STRING
        utils.assert.fail message "<string>" value
    .endif
.endm