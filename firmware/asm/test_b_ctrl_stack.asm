; Gate H1 Test B + E03 + E04 + WBS 1.4/1.5: test_b_ctrl_stack.asm
; Verifies DJNZ loop (4 iterations), SJMP forward skip, LCALL/RET stack push/pop, and @R0 indirect write.

        ORG 0000h
start:
        MOV A, #00h         ; [0000] 74 00 -> A=00h
        MOV R2, #04h        ; [0002] 7A 04 -> R2=04h
loop_sum:
        ADD A, #03h         ; [0004] 24 03 -> A += 3 (4 times -> 0Ch)
        DJNZ R2, loop_sum   ; [0006] DA FC -> R2-- ; loop if != 0
        MOV 30h, A          ; [0008] F5 30 -> RAM[30h]=0Ch
        SJMP after_trap     ; [000A] 80 02 -> skip trap instruction
trap:
        MOV A, #0FFh        ; [000C] 74 FF -> MUST NOT EXECUTE
after_trap:
        LCALL add_ten       ; [000E] 12 00 20 -> push 0011h (SP: 07h->09h), PC=0020h
ret_point:
        MOV 31h, A          ; [0011] F5 31 -> RAM[31h]=16h (0Ch + 0Ah)
        MOV R0, #40h        ; [0013] 78 40 -> R0=40h
        MOV @R0, A          ; [0015] F6    -> RAM[40h]=16h (indirect DATA write)
        MOV P1, #7Fh        ; [0016] 75 90 7F -> completion sentinel
done_b:
        SJMP done_b         ; [0019] 80 FE

        ORG 0020h
add_ten:
        ADD A, #0Ah         ; [0020] 24 0A -> A = 0Ch + 0Ah = 16h
        RET                 ; [0022] 22    -> pop 0011h (SP: 09h->07h), PC=0011h
        END
