# Gate H1 Sign-Off & Engineering Evidence Records (Section 11)

**Proyek:** 8051 Architecture Teardown — WBS Hari 1 (Sub-bab 1.1 – 1.8)  
**Core Reference:** `https://github.com/freecores/8051.git` | Commit: `f1a1ce31640c3e5c67935b649235e644462365a5` | Lisensi: `LGPL-2.1-or-later`  
**Toolchain (`tools.lock`):** `hpretl/iic-osic-tools:latest` — `iverilog 14.0 (devel)`, `vvp 14.0`, `verilator 5.052`, `yosys 0.70`, `python 3.12.3`

---

## Ringkasan Keputusan Gate H1

| Kriteria Gate H1 | Syarat Bootcamp | Status | Bukti Otomatis & Waveform |
|---|---|---|---|
| **Test A (Aritmetika & RAM)** | `MOV A,#05h → ADD A,#03h → MOV 30h,A` menghasilkan `RAM[30h] = 08h` dengan trace `PC/opcode/ACC/PSW/RAM` | **PASS** | `reports/test_a_sim.log`, `reports/test_a_trace.csv`, `reports/test_a_trace_check.md`, `traces/test_a.vcd` |
| **Test B (Loop & Call/Return)** | `DJNZ` loop 4x dan `LCALL/RET` menunjukkan `PC`, `SP`, stack, dan iterasi benar | **PASS** | `reports/test_b_sim.log`, `reports/test_b_trace.csv`, `reports/test_b_trace_check.md`, `traces/test_b.vcd` |
| **Test C (Mutation / Defect)** | Checker mendeteksi sedikitnya 1 defect yang disuntikkan (`PASS → FAIL → PASS`) | **PASS** | `reports/mut01_defect.diff`, `reports/test_a_mutated_sim.log`, `reports/test_a_mutated_trace_check.md`, `traces/test_a_mutated.vcd`, `reports/test_a_repaired_sim.log`, `reports/mutation.md` |

---

## Section 11 Engineering Evidence Records

### 1. Evidence Record — `E01`: Reset + Fetch + PC Progression

```text
Test ID / Requirement ID: E01 (WBS 1.2)    Core revision: freecores/8051 @ f1a1ce31640c3e5c67935b649235e644462365a5
Input program / firmware binary hash: firmware/asm/test_a_arith.hex (sha256: bca581539d13aaa778c86d99481c1b752403c4adfe4d34e000ca71ebffb0ed5e)
Simulator / assembler and version: Icarus Verilog 14.0 (devel) / scripts/asm8051.py (Python 3.12.3 / 3.8.4)
Command: docker run --rm -v C:/Users/ASUS/.gemini/antigravity/scratch/rtl-workspace/projects/8051_bootcamp:/work -w /work hpretl/iic-osic-tools:latest --skip bash /work/scripts/run_baseline_all.sh
Expected architectural signature: Reset SP=07h, PC=0000h; instruksi awal di 0000h opcode 74h (MOV A,#05h); fetch progresif 0000->0002->0004->0006->0007->...
Observed signature / first divergence: Cycle 12 (320.00 ns) booted=1, cur_pc=0000h, op1=74h, op2=05h, op_len=2; 0 divergences across 12 steps
Injected defect (if any) / result: None (clean baseline)
Status: PASS    Reviewer: Yoke Mikal / Assistant Cross-Check
What is proven: Reset active-high menginisialisasi PC=0000h dan SP=07h; warm-up prefetch 8-byte (cycle 1-11) mengisi idat_old/idat_cur dan mengeksekusi opcode awal di 0000h secara deterministik.
What is NOT proven: Fetch dengan wait-state ROM (DELAY > 0), internal Xilinx ROM (OC8051_ROM), dan instruction cache (OC8051_CACHE).
```

---

### 2. Evidence Record — `E02`: MOV / ADD / INC / SUBB & Store `RAM[30h] = 08h` (Gate H1 Test A)

```text
Test ID / Requirement ID: E02 / Gate H1 Test A (WBS 1.3)    Core revision: freecores/8051 @ f1a1ce31640c3e5c67935b649235e644462365a5
Input program / firmware binary hash: firmware/asm/test_a_arith.hex (sha256: bca581539d13aaa778c86d99481c1b752403c4adfe4d34e000ca71ebffb0ed5e)
Simulator / assembler and version: Icarus Verilog 14.0 (devel) + scripts/trace_checker.py
Expected architectural signature: RAM[30h]=08h, RAM[31h]=09h, RAM[32h]=07h, RAM[33h]=03h, RAM[34h]=C0h, final ACC=03h, PSW=C0h, SP=07h
Observed signature / first divergence: RAM30=08 RAM31=09 RAM34=c0 ACC=03 PSW=c0 SP=07 ([FINISH] PASS; 0 divergences across 12 instruction steps)
Injected defect (if any) / result: None (clean baseline)
Status: PASS    Reviewer: Yoke Mikal / Assistant Cross-Check
What is proven: Jalur datapath ALU ADD/SUB/INC, flag CY/AC/OV/P pada PSW, MOV direct-to-RAM, dan MOV PSW ke RAM (85 D0 34) berfungsi bit-exact.
What is NOT proven: Instruksi MUL, DIV, DA, XCH, serta instruksi bit-addressable kompleks di luar test_a.
```

---

### 3. Evidence Record — `E03`: DJNZ / Branch Control Flow (Gate H1 Test B part 1)

```text
Test ID / Requirement ID: E03 / Gate H1 Test B (WBS 1.5)    Core revision: freecores/8051 @ f1a1ce31640c3e5c67935b649235e644462365a5
Input program / firmware binary hash: firmware/asm/test_b_ctrl_stack.hex (sha256: df950dc004f1cb656ffaa96efef29c2dbbe9f94bb7a80b56f122bf881798c5cf)
Simulator / assembler and version: Icarus Verilog 14.0 (devel) + scripts/trace_checker.py
Expected architectural signature: 4 iterasi loop_sum (ADD A,#03h + DJNZ R2,-4), R2: 04->03->02->01->00, RAM[30h]=0Ch, SJMP melompati trap 000Ch
Observed signature / first divergence: RAM30=0c, R2=00, PC melompat 0006->0004 tepat 3 kali lalu fall-through ke 0008, SJMP 000A->000E; 0 divergences
Injected defect (if any) / result: None (clean baseline)
Status: PASS    Reviewer: Yoke Mikal / Assistant Cross-Check
What is proven: FSM decoder multi-cycle (state 00->10->01->00), comparator eq pada DJNZ, dan adder target relatif bertanda (pcs_result) pada SJMP/DJNZ bekerja akurat.
What is NOT proven: Conditional bit jump (JB/JBC/JNB), CJNE, dan XRAM access.
```

---

### 4. Evidence Record — `E04`: LCALL / RET, Stack & Indirect `@R0` (Gate H1 Test B part 2)

```text
Test ID / Requirement ID: E04 / Gate H1 Test B (WBS 1.4/1.5)    Core revision: freecores/8051 @ f1a1ce31640c3e5c67935b649235e644462365a5
Input program / firmware binary hash: firmware/asm/test_b_ctrl_stack.hex (sha256: df950dc004f1cb656ffaa96efef29c2dbbe9f94bb7a80b56f122bf881798c5cf)
Simulator / assembler and version: Icarus Verilog 14.0 (devel) + scripts/trace_checker.py
Expected architectural signature: LCALL push ret_pc=0011h -> SP=09h (RAM[08h]=11h, RAM[09h]=00h), subrutin add_ten ACC=16h, RET -> PC=0011h & SP=07h, @R0 -> RAM[40h]=16h
Observed signature / first divergence: max_sp=09, stk08=11, stk09=00, RAM31=16, RAM40=16, final SP=07 ([FINISH] PASS; 0 divergences across 20 instruction steps)
Injected defect (if any) / result: None (clean baseline)
Status: PASS    Reviewer: Yoke Mikal / Assistant Cross-Check
What is proven: Stack pre-increment push / post-decrement pop little-endian di RAM[08h..09h], pemulihan PC lewat RET, serta indirect RAM addressing lewat oc8051_indi_addr1.
What is NOT proven: Stack overflow ke area upper IDATA (80h..FFh) dan nested interrupt RETI (bagian WBS Hari 2).
```

---

### 5. Evidence Record — `E08`: Mutation Injection, Detection & Regression (Gate H1 Test C)

```text
Test ID / Requirement ID: E08 / Gate H1 Test C (WBS 1.8)    Core revision: rtl_mutation (forked from f1a1ce31640c3e5c67935b649235e644462365a5)
Input program / firmware binary hash: firmware/asm/test_a_arith.hex (sha256: bca581539d13aaa778c86d99481c1b752403c4adfe4d34e000ca71ebffb0ed5e)
Simulator / assembler and version: Icarus Verilog 14.0 (devel) + scripts/trace_checker.py
Expected architectural signature: Baseline PASS -> Injected MUT-01 FAIL (first divergence at Step 1 PC=0002h) -> Repaired PASS
Observed signature / first divergence: Mutated TB reported [TB_ERROR] RAM[30h] expected 08h, got 09 ([FINISH] FAIL errors=5); trace_checker.py failed at Step 1 (cyc 13->15, t=380.00ns, PC=0002h ADD A,#03h: ACC exp=08 obs=09). Post-repair regression test_a & test_b returned [FINISH] PASS and 0 divergences.
Injected defect (if any) / result: MUT-01 (rtl_mutation/oc8051_alu.v:162 assign add3 = {3'b000,1'b1}) -> Caught & Repaired (0-byte diff vs rtl_reference)
Status: PASS    Reviewer: Yoke Mikal / Assistant Cross-Check
What is proven: Self-checking TB dan golden trace_checker mampu mendeteksi bug single-bit datapath hingga ke instruksi dan cycle pertama terjadinya penyimpangan (siklus PASS-FAIL-PASS lengkap).
What is NOT proven: Cakupan mutasi menyeluruh di decoder/timer/interrupt controller (lanjut di WBS Hari 2).
```
