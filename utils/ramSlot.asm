;====
; Sets a utils.ramSlot value to either the user-defined
; smslib.RAM_SLOT value or via a mapper (mapper.RAM_SLOT)
;
; @fail if value cannot be determined
;====
.ifdef smslib.RAM_SLOT
    .redefine utils.ramSlot smslib.RAM_SLOT
.else
    .ifdef mapper.RAM_SLOT
        .redefine utils.ramSlot mapper.RAM_SLOT
    .else
        .print "smslib: Unsure which RAM slot to use:"
        .print " Either include .define an smslib.RAM_SLOT value or include an "
        .print " smslib mapper before including the others modules"
        .print "\n\n"
        .fail
    .endif
.endif
