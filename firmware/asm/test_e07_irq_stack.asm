; WBS 2.3 & 2.4 / E07 - Timer 0 Interrupt Vector 000Bh, Stack Budget & RETI
    ORG 0000h
    LJMP main
    ORG 000Bh
    LJMP isr_t0

    ORG 0030h
main:
    MOV 20h, #00h       ; Clear bit-addressable flags (RAM20.0 = 0)
    MOV 30h, #00h       ; Clear ISR hit counter
    MOV A, #55h         ; Main context signature ACC = 55h
    SETB C              ; Main context signature PSW.7 (CY) = 1
    MOV TMOD, #02h      ; Timer 0 Mode 2 auto-reload
    MOV TH0, #0FDh      ; Reload FDh -> 3 prescaler ticks (36 cycles) to IRQ
    MOV TL0, #0FDh      ; Start TL0 = FDh
    MOV IE, #82h        ; EA=1 (bit7), ET0=1 (bit1)
    SETB TR0            ; Start Timer 0
wait_isr:
    JNB RAM20.0, wait_isr
    MOV 31h, A          ; Capture restored ACC (must equal 55h)
    MOV 32h, PSW        ; Capture restored PSW (bit7 CY must equal 1)
    MOV P1, #7Fh        ; Sentinel completion
done_e07:
    SJMP done_e07

    ORG 0060h
isr_t0:
    PUSH ACC            ; SP: 09h -> 0Ah, RAM[0Ah] = 55h
    PUSH PSW            ; SP: 0Ah -> 0Bh (max_sp = 0Bh)
    MOV A, #0AAh        ; Deliberately clobber ACC inside ISR
    ADD A, #01h         ; ACC = ABh, clears CY = 0!
    INC 30h             ; RAM[30h] = 01h
    MOV P0, #0A5h       ; Marker P0 = A5h inside ISR
    CLR TR0             ; Stop Timer 0
    SETB RAM20.0        ; Signal main loop ISR finished
    POP PSW             ; Restore PSW (CY=1!), SP: 0Bh -> 0Ah
    POP ACC             ; Restore ACC (55h!), SP: 0Ah -> 09h
    RETI                ; Pop return PC & clear int_proc, SP: 09h -> 07h
    END
