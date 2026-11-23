# Gate H2 Sign-Off, Review Risiko & Engineering Evidence Records (Hari 2)

**Proyek:** 8051 Architecture Teardown → EduRV-32 → ESP32-C3-Class MCU (**WBS Hari 2: 2.1 – 2.8**)  
**Core Reference (Read-Only):** `https://github.com/freecores/8051.git` @ `f1a1ce31640c3e5c67935b649235e644462365a5` (`LGPL-2.1-or-later`)  
**Toolchain (`tools.lock`):** `hpretl/iic-osic-tools:latest` (`iverilog 14.0`, `vvp 14.0`, `verilator 5.052`, `yosys 0.70`, `gtkwave`, `surfer 0.7.0`, `python 3.12.3`)

---

## 1. Checklist Pemenuhan Minimum Gate H2 (YEKVO Seksi 5)

| Syarat Wajib Gate H2 | Artifact / Bukti di Repositori | Status |
|---|---|---:|
| **Simulasi E05 (GPIO SFR / Pin & RMW)** | `reports/e05_gpio_sim.log`, `reports/e05_gpio_trace.csv`, `traces/e05_gpio.vcd`, `evidence/wbs_2_1_gpio_sfr_trace.md` | **PASS** |
| **Simulasi E06 (Timer Tick, ÷12 Prescaler & Reload)** | `reports/e06_timer_sim.log`, `reports/e06_timer_trace.csv`, `traces/e06_timer.vcd`, `evidence/wbs_2_2_timer_trace.md` | **PASS** |
| **Simulasi E07 (Interrupt Vector 000Bh, RETI & Stack)** | `reports/e07_irq_sim.log`, `reports/e07_irq_trace.csv`, `traces/e07_irq.vcd`, `evidence/wbs_2_3_2_4_irq_stack_record.md` | **PASS** |
| **1 Architecture Diagram (`D06`)** | `spec/yekvo32_architecture.md`, `evidence/figures/fig_d2_4_yekvo32_architecture.png` | **PASS** |
| **1 Draft Memory Map Eksplisit (bukan ESP32)** | `spec/yekvo32_architecture.md` (`0x0000_0000` ROM, `0x2000_0000` SRAM, `0x4000_0000..3FFF` MMIO) | **PASS** |
| **1 HW/SW Register Contract (`D07`)** | `spec/mmio_contract.csv` (19 register: `GPIO0`, `TIMER0`, `UART0`, `IRQ_CTRL`) | **PASS** |
| **1 Daftar Perbedaan dengan EduRV-32 (`WBS 2.5`)** | `docs/gap_matrix_8051_edurv32.md` | **PASS** |
| **1 Verification Plan & Benchmark ESP32-C3 (`D08`)** | `spec/benchmark_plan.md` | **PASS** |

---

## 2. Engineering Evidence Records Formal (Format Seksi 11)

### Evidence Record — `E05`: GPIO SFR Decode, Byte/Bit Write, RMW Latch & Pin Read

```text
Test ID / Requirement ID: E05 (WBS 2.1)    Core revision: freecores/8051 @ f1a1ce31640c3e5c67935b649235e644462365a5
Input program / firmware binary hash: firmware/asm/test_e05_gpio.hex (sha256: 8733b1ab9676c9dbea78ce62083c6d94fe4d6cacf5a09c34064670f73f696ec6)
Simulator / assembler and version: Icarus Verilog 14.0 (devel) / scripts/asm8051.py
Command: bash /foss/designs/8051_bootcamp/scripts/run_in_iic_osic.sh scripts/run_day2_all.sh
Expected architectural signature: p0_o sequence 5A->5B->59->A9 (RMW reads p0_out), p3_o=3Ch, RAM[30h]=A5h (p2_i), RAM[31h]=C3h (p0_i != latch A9h)
Observed signature / first divergence: cyc=31, P0_o=a9, P3_o=3c, RAM30=a5, RAM31=c3 ([FINISH] PASS; 0 errors)
Injected defect (if any) / result: None
Status: PASS    Reviewer: Yoke Mikal / Cross-Review: ____________
What is proven: Dekode SFR direct (!wr_ind), byte & bit addressing pada oc8051_ports1, serta perbedaan nyata mux baca rmw=1 (output latch) vs rmw=0 (pin fisik pX_in).
What is NOT proven: Sinyal tristate open-drain fisik pada pad I/O tingkat board dan sinkronisasi metastabilitas 2-FF untuk pin asinkron.
```

---

### Evidence Record — `E06`: Timer 0 Mode 2 Prescaler ÷12, Auto-Reload & Overflow Polling

```text
Test ID / Requirement ID: E06 (WBS 2.2)    Core revision: freecores/8051 @ f1a1ce31640c3e5c67935b649235e644462365a5
Input program / firmware binary hash: firmware/asm/test_e06_timer.hex (sha256: e993582121e48e9c033b217f3bbdbf0d3d38ad3e5661aad9b77148c847ad5a53)
Simulator / assembler and version: Icarus Verilog 14.0 (devel) / scripts/asm8051.py
Command: bash /foss/designs/8051_bootcamp/scripts/run_in_iic_osic.sh scripts/run_day2_all.sh
Expected architectural signature: 2x overflow Mode 2 (TH0=FCh), jarak tepat 4x12=48 clock/overflow, auto-reload TL0=FCh -> RAM[30h]=FCh, RAM[31h]=FCh, RAM[32h]=02h, P0_o=02h
Observed signature / first divergence: Ovf #1 @ cyc=63 (1340ns), Ovf #2 @ cyc=111 (2300ns, delta=48 cyc tepat); RAM30=fc, RAM31=fc, RAM32=02, P0_o=02 ([FINISH] PASS)
Injected defect (if any) / result: None
Status: PASS    Reviewer: Yoke Mikal / Cross-Review: ____________
What is proven: Prescaler ÷12 (oc8051_sfr.v), Mode 2 8-bit auto-reload TL0<=TH0, penguncian & polling/clear bit TF0 (TCON.5), serta penghentian counter via CLR TR0.
What is NOT proven: Mode 0/1/3 pada Timer 0/1, mode external counter (pin T0/T1), dan fitur auto-capture Timer 2 (oc8051_tc2).
```

---

### Evidence Record — `E07`: Timer 0 Interrupt Vector `000Bh`, Stack Context Save/Restore & `RETI`

```text
Test ID / Requirement ID: E07 (WBS 2.3 & 2.4)    Core revision: freecores/8051 @ f1a1ce31640c3e5c67935b649235e644462365a5
Input program / firmware binary hash: firmware/asm/test_e07_irq_stack.hex (sha256: 6edf4f1be5265f4531c15e6780761d922e2439ba6655d062ab564112b13c4f5d)
Simulator / assembler and version: Icarus Verilog 14.0 (devel) / scripts/asm8051.py
Command: bash /foss/designs/8051_bootcamp/scripts/run_in_iic_osic.sh scripts/run_day2_all.sh
Expected architectural signature: intr=1 vec=0Bh, hardware push ret PC 0047h (stk08=47,stk09=00), ack=1, PUSH ACC/PSW max_sp=0Bh (stk0a=55,stk0b=80), clobber ACC=ABh/CY=0, RETI (SP=07h, int_proc=0), main captures RAM[31h]=55h & RAM[32h].7=1
Observed signature / first divergence: cyc=100, intr=1, ack=1, reti=1, max_sp=0b, SP=07, int_proc=0, stk08..0b=47,00,55,80, P0_o=a5, RAM20=01, RAM30..32=01,55,80 ([FINISH] PASS)
Injected defect (if any) / result: None
Status: PASS    Reviewer: Yoke Mikal / Cross-Review: ____________
What is proven: Injeksi sintetis LCALL 000Bh oleh memory_interface, auto-clear TF0 lewat int_ack, penyelamatan konteks ACC/PSW dari clobber ISR, dan pemulihan PC/SP/int_proc oleh RETI.
What is NOT proven: Preemption simultan 2 level IP=1 di atas IP=0 dan external interrupt edge/level timing di pin fisik int0_i/int1_i.
```

---

## 3. Risk & Dependency Review + Action Backlog Lanjutan (`M1–M5` EduRV-32)

| Risiko / Ketergantungan Teknis | Dampak | Mitigasi Terverifikasi |
|---|---|---|
| **Polaritas `int0_i`/`int1_i` aktif rendah** | Bila dibiarkan `0` saat `EA=1`, ISR eksternal terpicu terus-menerus | Teridentifikasi di `oc8051_int.v:249` & diterapkan idle HIGH (`1'b1`) di TB; di YEKVO32 polaritas dibuat dapat dikonfigurasi eksplisit |
| **Selisih lebar data 8-bit vs 32-bit RV32** | Strategi context save 8051 (2B) tidak cukup untuk 32-bit ABI (`64B` frame) | Diperhitungkan dalam budget SRAM `32 KB` dan desain register `GPIO_SET`/`CLR` atomik pada `mmio_contract.csv` |
| **Kesiapan C Compiler RISC-V** | Simulasi M2–M3 butuh `riscv32-unknown-elf-gcc` untuk kompilasi `crt0.S` & HAL C | Cek/instal toolchain RISC-V di container IIC-OSIC / WSL sebelum masuk Milestone M3 |

### Action Backlog Pasca-Bootcamp (Sesuai Seksi 8 & 12 YEKVO)
1. **Sprint 1 — `M1` CPU Reconstruction (EduRV-32 Bab 0–11):** Bangun core RV32I single-cycle independen + verifikasi step-by-step trace regression & mutation testing.
2. **Sprint 2 — Pipeline Upgrade (EduRV-32 Bab 13–17):** Kembangkan multicycle & 5-stage pipeline (forwarding + hazard detection + CSR `mtvec/mepc/mcause/mret`).
3. **Sprint 3 — `M2` MCU SoC Integration (Bab 18–20):** Implementasikan RTL untuk Boot ROM, SRAM 32 KB, Bus Matrix, `GPIO0`, `TIMER0`, `UART0`, dan `IRQ_CTRL` sesuai persis `D06` (`spec/yekvo32_architecture.md`) & `D07` (`spec/mmio_contract.csv`).
4. **Sprint 4 — `M3 & M4` Firmware HAL & Benchmark ESP32-C3:** Tulis `crt0.S` + HAL C + eksekusi skenario `BM-01`..`BM-05` (`spec/benchmark_plan.md`) melawan board ESP32-C3; lanjut ASIC readiness (Bab 21–22) hanya pada baseline yang terverifikasi.

---

## 4. Lembar Sign-Off Akhir Bootcamp (Format Seksi 12 YEKVO)

```text
Keputusan Bootcamp:
  [ X ] H1 PASS    (Test A, Test B, Test C / E01–E04, E08 terverifikasi)
  [ X ] H2 PASS    (E05, E06, E07 live PASS + D06, D07, D08, Gap Matrix lengkap)
  [   ] Individual assessments recorded  (Defense 5–7 menit oleh Yoke Mikal)
  [ X ] D01–D08 accepted (teknis internal selesai; menunggu paruh review instruktur)
  [ X ] Action backlog approved (EduRV-32 Bab 0–22)

Peserta / RTL Owner : Yoke Mikal
Instructor/Reviewer : __________________________    Date: ________________
```
