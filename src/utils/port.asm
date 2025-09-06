;====
; Performs a simple 'in' operation to read the given port. This serves to
; decouple the modules from this operation so it could be stubbed out with a
; fake version for testing purposes
;====

.define utils.port

;====
; Reads the given port into register A
;
; @in   portNumber  the port to read
; @out  a           the read value
;====
.macro "utils.port.read" args portNumber
    in a, (portNumber)
.endm
