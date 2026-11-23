; WBS 2.1 / E05 - GPIO SFR Decode, Byte/Bit Write, RMW Latch & Pin Read
    ORG 0000h
start_e05:
    MOV P0, #5Ah        ; p0_o: FFh -> 5Ah (byte direct write to SFR 80h)
    SETB P0.0           ; p0_o: 5Ah -> 5Bh (bit-addressable write, bit 80h)
    CLR P0.1            ; p0_o: 5Bh -> 59h (bit-addressable clear, bit 81h)
    XRL P0, #0F0h       ; p0_o: 59h XOR F0h = A9h (rmw=1 reads p0_out!)
    MOV P3, #3Ch        ; p3_o: FFh -> 3Ch (byte direct write to SFR B0h)
    MOV A, P2           ; rmw=0 reads external pin p2_i = A5h
    MOV 30h, A          ; RAM[30h] = A5h
    MOV A, P0           ; rmw=0 reads external pin p0_i = C3h (NOT latch A9h!)
    MOV 31h, A          ; RAM[31h] = C3h
    MOV P1, #7Fh        ; Sentinel completion
done_e05:
    SJMP done_e05
    END
