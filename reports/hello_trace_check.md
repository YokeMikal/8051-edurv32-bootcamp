# Trace Check Report: `hello_trace.csv` vs `hello.in`

| Step | Decode Cyc | Commit Cyc | Time(ns) | PC | Op | Mnemonic | Exp (ACC/PSW[7:1]/SP/RAM30) | Obs (ACC/PSW/SP/RAM30) | Status |
|---:|---:|---:|---:|---|---|---|---|---|---|
| 0 | 12 | 14 | 36000 | 0000 | 74 | `MOV A,#55h` | 55 / 00 / 07 / 00 | 55 / 00 / 07 / 00 | **PASS** |
| 1 | 13 | 15 | 38000 | 0002 | F5 | `MOV 80h,A` | 55 / 00 / 07 / 00 | 55 / 00 / 07 / 00 | **PASS** |
| 2 | 14 | 16 | 40000 | 0004 | F4 | `CPL A` | AA / 00 / 07 / 00 | AA / 00 / 07 / 00 | **PASS** |
| 3 | 15 | 17 | 42000 | 0005 | F5 | `MOV 30h,A` | AA / 00 / 07 / AA | AA / 00 / 07 / AA | **PASS** |
| 4 | 16 | 18 | 44000 | 0007 | 75 | `MOV 90h,#7Fh` | AA / 00 / 07 / AA | AA / 00 / 07 / AA | **PASS** |
| 5 | 17 | 19 | 46000 | 000A | 80 | `SJMP -2` | AA / 00 / 07 / AA | AA / 00 / 07 / AA | **PASS** |

**Verdict:** `PASS` (6 instruction boundaries verified against golden 8051 ISA model with 0 divergences).
