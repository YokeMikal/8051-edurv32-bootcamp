; P-02 Smoke Baseline Firmware: hello.asm
; Demonstrates basic ACC load, Port 0 output, bit complement, RAM write, and PASS sentinel on P1.

        ORG 0000h
start:
        MOV A, #55h         ; A = 55h
        MOV P0, A           ; P0 = 55h
        CPL A               ; A = AAh
        MOV 30h, A          ; RAM[30h] = AAh
        MOV P1, #7Fh        ; Signal completion to TB
done:
        SJMP done
        END
