; WBS 2.2 / E06 - Timer 0 Mode 2 Auto-Reload, Prescaler /12 & Polling
    ORG 0000h
start_e06:
    MOV TMOD, #02h      ; Timer 0 Mode 2 (8-bit auto-reload)
    MOV TH0, #0FCh      ; Auto-reload value = FCh (4 prescaled ticks per overflow)
    MOV TL0, #0FCh      ; Initial TL0 = FCh
    MOV R3, #00h        ; Overflow hit counter = 0
    CLR TF0             ; Ensure TF0 (TCON.5, bit 8Dh) clear before start
    SETB TR0            ; Start Timer 0 (TCON.4 = 1)
wait_ovf1:
    JNB TF0, wait_ovf1  ; Poll TF0 until Overflow #1
    MOV 30h, TL0        ; Capture auto-reloaded TL0 (FCh)
    CLR TF0             ; Clear TF0
    INC R3              ; R3 = 01h
    MOV P0, #01h        ; Pin marker: Overflow #1 seen
wait_ovf2:
    JNB TF0, wait_ovf2  ; Poll TF0 until Overflow #2
    CLR TR0             ; Stop Timer 0
    MOV 31h, TL0        ; Capture auto-reloaded TL0 (FCh)
    CLR TF0             ; Clear TF0
    INC R3              ; R3 = 02h
    MOV 32h, R3         ; RAM[32h] = 02h
    MOV P0, #02h        ; Pin marker: Overflow #2 seen
    MOV P1, #7Fh        ; Sentinel completion
done_e06:
    SJMP done_e06
    END
