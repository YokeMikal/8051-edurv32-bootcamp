; Gate H1 Test A + E01 + E02 + WBS 1.2/1.3: test_a_arith.asm
; Verifies MOV, ADD, INC, SUBB, PSW flags (CY, AC, OV, P), and internal RAM store at 30h..34h.

        ORG 0000h
start:
        MOV A, #05h         ; [0000] 74 05 -> A=05h, PSW=00h
        ADD A, #03h         ; [0002] 24 03 -> A=08h, PSW=01h (P=1)
        MOV 30h, A          ; [0004] F5 30 -> RAM[30h]=08h (Gate H1 Test A core)
        INC A               ; [0006] 04    -> A=09h, PSW=00h (P=0)
        MOV 31h, A          ; [0007] F5 31 -> RAM[31h]=09h
        SUBB A, #02h        ; [0009] 94 02 -> A=07h, PSW=01h (CY=0, P=1)
        MOV 32h, A          ; [000B] F5 32 -> RAM[32h]=07h
        ADD A, #0FCh        ; [000D] 24 FC -> 07h + FCh = 103h -> A=03h, CY=1 AC=1 OV=0 P=0 -> PSW=C0h
        MOV 33h, A          ; [000F] F5 33 -> RAM[33h]=03h
        MOV 34h, PSW        ; [0011] 85 D0 34 -> RAM[34h]=C0h (capture flags)
        MOV P1, #7Fh        ; [0014] 75 90 7F -> completion sentinel
done:
        SJMP done           ; [0017] 80 FE
        END
