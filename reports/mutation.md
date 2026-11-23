# WBS 1.8 / D05 / E08 — Mutation Injection, Diagnosis, Repair & Regression Report

**Experiment ID:** `E08` (Gate H1 Test C)  
**Target Branch Isolasi:** `rtl_mutation/` (salinan terisolasi; `rtl_reference/` tetap read-only & tidak tersentuh, diverifikasi `git status --short` kosong)  
**Defect ID:** `MUT-01` — Carry-in stuck-at-1 pada adder utama ALU (`rtl_mutation/oc8051_alu.v:162`)

---

## 1. Siklus E08: **PASS → FAIL → PASS**

| Tahap | Target RTL | Command | Hasil Simulasi TB | Hasil `trace_checker.py` | Nilai Kunci `RAM[30h]` |
|---|---|---|---|---|---|
| **1. PASS (Baseline)** | `rtl_reference/rtl/verilog` | `scripts/run_baseline_all.sh` | `[FINISH] PASS` (`test_a`, `test_b`, `hello`) | `PASS` (exit 0) | `08h` (`test_a`), `0Ch` (`test_b`) |
| **2. FAIL (Defect Injected)** | `rtl_mutation` (`MUT-01`) | `scripts/run_mutated_test_a.sh` | `[FINISH] FAIL errors=5` | `FAIL` (exit 1, tangkap di Step 1) | **`09h` (salah, seharusnya `08h`)** |
| **3. PASS (Repaired)** | `rtl_mutation` (repaired) | `scripts/run_repaired_regression.sh` | `[FINISH] PASS` (`test_a` & `test_b`) | `PASS` (exit 0) | **`08h`** (`test_a`), `0Ch` (`test_b`) |

---

## 2. Defect Patch (`reports/mut01_defect.diff`)

```diff
--- a/oc8051_alu.v
+++ b/oc8051_alu.v
@@ -159,7 +159,7 @@
 /* Add */
 assign add1 = {1'b0,src1[3:0]};
 assign add2 = {1'b0,src2[3:0]};
-assign add3 = {3'b000,srcCy};
+assign add3 = {3'b000,1'b1}; // MUT-01 injected carry-in stuck-at-1
 assign add4 = add1+add2+add3;
 
 assign add5 = {1'b0,src1[6:4]};
```

---

## 3. Bukti Kegagalan & First Divergence (`test_a_mutated_sim.log` + `test_a_mutated_trace_check.md`)

1. **Testbench Self-Check Failure (`reports/test_a_mutated_sim.log`):**
   ```text
   [TB_ERROR] test_a (Gate H1 Test A): RAM[30h] expected 08h, got 09
   [TB_ERROR] test_a: RAM[31h] expected 09h, got 0a
   [TB_ERROR] test_a: RAM[32h] expected 07h, got 08
   [TB_ERROR] test_a: RAM[33h] expected 03h, got 05
   [TB_ERROR] test_a: Final ACC=05(exp 03h) PSW=c0(exp C0h) SP=07(exp 07h)
   [FINISH] FAIL errors=5
   ```
2. **Golden Trace Checker (`reports/test_a_mutated_trace_check.md`):**
   - Menangkap error tepat pada **Step 1 (`PC=0002h`, `ADD A,#03h`)**, Decode Cycle **13**, Commit Cycle **15** (`t = 380.00 ns`):
     - `Expected`: `ACC = 08h` (`05h + 03h + 0`)
     - `Observed`: `ACC = 09h` (`05h + 03h + 1`)
3. **Waveform:** `traces/test_a_mutated.vcd` (bandingkan sinyal `dut.alu_cy = 0`, `dut.src1 = 03h`, `dut.src2 = 05h`, tetapi `dut.des_acc = 09h` pada Cycle 14!).

---

## 4. Perbaikan (Repair) & Regresi Pasca-Perbaikan

- **Perbaikan:** `rtl_mutation/oc8051_alu.v` line 162 dikembalikan menjadi `assign add3 = {3'b000,srcCy};`. Hasil verifikasi byte-diff terhadap `rtl_reference/rtl/verilog/oc8051_alu.v` adalah **0 byte** (`REPAIR_DIFF_BYTES=0`).
- **Regresi (`reports/test_a_repaired_sim.log` & `reports/test_b_repaired_sim.log`):**
  - `test_a`: `[TB_INFO] Simulation Finished!` + `[FINISH] PASS` (`RAM[30h] = 08h`, `RAM[34h] = C0h`, `ACC = 03h`). `trace_checker.py` exit `0` (12/12 steps).
  - `test_b`: `[TB_INFO] Simulation Finished!` + `[FINISH] PASS` (`RAM[30h] = 0Ch`, `RAM[31h] = 16h`, `RAM[40h] = 16h`, `max_sp = 09h`, `SP = 07h`). `trace_checker.py` exit `0` (20/20 steps).
- **Integritas Master Core:** `git -C rtl_reference status --short` bersih (kosong).
