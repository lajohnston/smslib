.define utils.ram

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
        .print "\.: Unsure which RAM slot to use:"
        .print " Either .define an smslib.RAM_SLOT value or include an "
        .print " smslib mapper before including the other modules"
        .print "\n\n"
        .fail
    .endif
.endif
