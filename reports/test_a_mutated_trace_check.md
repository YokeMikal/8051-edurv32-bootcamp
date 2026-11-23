# Trace Check Report: `test_a_mutated_trace.csv` vs `test_a_arith.in`

| Step | Decode Cyc | Commit Cyc | Time(ns) | PC | Op | Mnemonic | Exp (ACC/PSW[7:1]/SP/RAM30) | Obs (ACC/PSW/SP/RAM30) | Status |
|---:|---:|---:|---:|---|---|---|---|---|---|
| 0 | 12 | 14 | 36000 | 0000 | 74 | `MOV A,#05h` | 05 / 00 / 07 / 00 | 05 / 00 / 07 / 00 | **PASS** |
| 1 | 13 | 15 | 38000 | 0002 | 24 | `ADD A,#03h` | 08 / 00 / 07 / 00 | 09 / 00 / 07 / 00 | **FAIL** |

**Verdict:** `FAIL` — **First Divergence Detected!**

- **Step:** 1
- **Decode Cycle / Commit Cycle:** 13 / 15 (time=38000 ns)
- **PC / Opcode / Instruction:** `0002h` / `24` / `ADD A,#03h`
- **Mismatched Signals:** ACC: exp=08 obs=09
