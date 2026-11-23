# WBS 1.7 — Automated Trace Comparison & First-Divergence Diagnosis

**Golden Checker:** `scripts/trace_checker.py` (memodelkan ISA 8051 step-by-step terhadap `PC`, `op1`, `ACC`, `PSW[7:1]`, `SP`, `R0`, `R2`, `RAM[30h..34h]`, `RAM[40h]`, `STK[08h..09h]`, `P0`, `P1`)  
**Sumber Trace RTL:** `reports/*_trace.csv` (dihasilkan oleh `iverilog 14.0` + `vvp` di Docker `hpretl/iic-osic-tools:latest`)

---

## 1. Ringkasan Hasil Perbandingan Golden Model vs DUT

| Test | Firmware | Trace CSV | Jumlah Step Diperiksa | Status | Laporan Detail |
|---|---|---|---:|:---:|---|
| **P-02 Smoke** | `hello.in` | `reports/hello_trace.csv` | 6 | **PASS** | `reports/hello_trace_check.md` |
| **Gate H1 Test A (E01/E02)** | `test_a_arith.in` | `reports/test_a_trace.csv` | 12 | **PASS** | `reports/test_a_trace_check.md` |
| **Gate H1 Test B (E03/E04)** | `test_b_ctrl_stack.in` | `reports/test_b_trace.csv` | 20 | **PASS** | `reports/test_b_trace_check.md` |
| **Defect Check (MUT-01)** | `test_a_arith.in` | `reports/test_a_mutated_trace.csv` | 2 (berhenti di divergence #1) | **FAIL (Caught!)** | `reports/test_a_mutated_trace_check.md` |
| **Post-Repair Test A** | `test_a_arith.in` | `reports/test_a_repaired_trace.csv` | 12 | **PASS** | `reports/test_a_repaired_trace_check.md` |
| **Post-Repair Test B** | `test_b_ctrl_stack.in` | `reports/test_b_repaired_trace.csv` | 20 | **PASS** | `reports/test_b_repaired_trace_check.md` |

---

## 2. Temuan Arsitektural RTL Selama Penyelarasan Trace (Pipelining Real)

Selama WBS 1.7, pencocokan cycle-per-cycle terhadap DUT mengungkap dua perilaku pipeline nyata dari `oc8051`:

1. **SP Overlap saat `RET` (`test_b_trace.csv` Cycle 43–45):**
   - Pada `PC=0020h` (`ADD A,#0Ah`, decode Cycle 42), instruksi `RET` (`0022h`) masuk decode tepat di Cycle 43 (`cyc_d + 1`).
   - `oc8051_sp1` mengurangi `sp_out` secara kombinasional pada tahap pop pertama `RET` di Cycle 44 (`09h → 08h`), bersamaan dengan cycle commit `ACC = 16h` milik `ADD`.
   - `trace_checker.py` mendeteksi kondisi overlap ini (`nxt_cyc == cyc_d + 1` untuk instruksi stack) dan memeriksa `SP` sebelum overlap (`cyc_d + 1`), serta memeriksa `SP` hasil `RET` setelah pop selesai (`cyc_d + 2 = Cycle 45`, `SP = 07h`).
2. **Parity Bit `PSW[0]` Lookahead (`oc8051_acc.v:97`):**
   - Sinyal `p = ^acc` dihitung dari output mux kombinasional *sebelum* flip-flop `data_out`, sehingga `PSW[0]` merefleksikan paritas hasil instruksi berikutnya 1 cycle lebih awal ketika dua instruksi yang mengubah `ACC` berurutan. Bit status aritmetika `PSW[7:1]` (`CY, AC, F0, RS1, RS0, OV`) ter-latch penuh bersama `ACC` di `cyc_d + 2`.

---

## 3. Diagnosis First Divergence (`test_a_mutated_trace.csv`)

Saat `MUT-01` aktif di `rtl_mutation/oc8051_alu.v`, `trace_checker.py` langsung menghentikan pengecekan pada **Step 1**:

```text
Step               : 1
Decode / Commit    : Cycle 13 / Cycle 15 (time = 380.00 ns)
PC / Opcode        : 0002h / 24h (ADD A, #03h)
Expected State     : ACC = 08h, PSW[7:1] = 00h
Observed State     : ACC = 09h, PSW = 00h
Mismatch           : ACC: exp=08 obs=09
```

**Diagnosis Akar Masalah:**
- Step 0 (`0000h: MOV A, #05h`) lolos karena tidak memakai jalur `ALU_ADD` (`ACC = 05h`).
- Step 1 (`0002h: ADD A, #03h`) masuk ke `oc8051_alu1` dengan `src1=03h`, `src2=05h`, `srcCy=0`. Karena `add3` terkunci ke `3'b001` (`1'b1`) alih-alih `{3'b000, srcCy}`, hasil penjumlahan bertambah `+1` menjadi `09h` — yang kemudian berpropagasi membuat `RAM[30h]` menjadi `09h` alih-alih `08h`.
