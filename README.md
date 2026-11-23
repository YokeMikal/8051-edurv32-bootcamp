# 8051 Architecture Teardown -> YEKVO32 (EduRV-32) MCU Specification

Repositori hasil kerja **RTL Engineer (WBS Hari 1 & Hari 2)** berbasis core **OpenCores `oc8051`** (`freecores/8051`, read-only) dan toolchain open-source **IIC-OSIC-TOOLS (`hpretl/iic-osic-tools:latest`)** di **WSL2 Ubuntu + Docker**.

- **Peserta / RTL Engineer:** Yoke Mikal
- **Core Referensi:** [`freecores/8051`](https://github.com/freecores/8051) (commit `f1a1ce31640c3e5c67935b649235e644462365a5`, lisensi `LGPL-2.1-or-later`)
- **Status Kelulusan:** **Gate H1 PASS** (Hari 1) & **Gate H2 PASS** (Hari 2)

---

## 1. Tujuan & Alur Besar Proyek

1. **Hari 1 — *Understand the 8051 Machine* (`WBS 1.1 – 1.8`, `Gate H1`):**
   Membedah anatomi CPU 8051 di level RTL (`oc8051_top`, prefetch 8-byte, `oc8051_decoder`, `oc8051_alu`, memory interface `wr_ind`, stack `SP`), menulis program assembly uji, menjalankan simulasi self-checking, membandingkan trace cycle-per-cycle terhadap *golden ISA model* (`trace_checker.py`), dan memvalidasi ketajaman testbench lewat *mutation testing* (`MUT-01`: `PASS -> FAIL -> PASS`).
2. **Hari 2 — *HW/SW Contract -> RV32 MCU Specification* (`WBS 2.1 – 2.8`, `Gate H2`):**
   Menguji kontrak hardware/software pada peripheral asli `oc8051` (**GPIO** `rmw` latch vs pin, **Timer 0 Mode 2** prescaler `÷12` auto-reload, serta **Interrupt Vector `000Bh`**, `RETI`, dan *stack budget*), lalu menyusun *Gap Matrix `8051 <-> EduRV-32`*, arsitektur MCU minimal **YEKVO32** (peta memori eksplisit non-ESP32), kontrak **19 register MMIO**, rencana verifikasi `L1–L4`, dan proposal benchmark **ESP32-C3** (`BM-01..BM-05`).

---

## 2. Struktur Direktori & Daftar Deliverable

| Path | WBS / ID | Isi & Kegunaan |
|---|---|---|
| `rtl_reference/` | `P-01` (Read-Only) | Core referensi `freecores/8051` (tidak diubah; bersih terhadap upstream) |
| `rtl_mutation/` | `WBS 1.8` (`E08`) | Salinan terisolasi untuk uji mutasi `MUT-01` (`oc8051_alu.v`), sudah dipulihkan 0-byte diff |
| `docs/8051_architecture.md` | `WBS 1.1` (`D01`) | Port top-level `oc8051_top`, clock/reset, diagram blok, dan hierarki 27 modul |
| `docs/8051_contract.md` | `WBS 1.4` (`D02`) | Peta memori `CODE/DATA/IDATA/SFR/XDATA`, decoder `wr_ind`, dan aturan stack |
| `docs/gap_matrix_8051_edurv32.md` | `WBS 2.5` | Matriks perbandingan 9 dimensi teknis `oc8051` vs `EduRV-32` (`RV32I`) |
| `spec/yekvo32_architecture.md` | `WBS 2.6` (`D06`) | Spesifikasi arsitektur SoC `yekvo32_mcu_top` & draft memory map eksplisit |
| `spec/mmio_contract.csv` | `WBS 2.6` (`D07`) | Kontrak 19 register MMIO 32-bit (`GPIO0`, `TIMER0`, `UART0`, `IRQ_CTRL`) |
| `spec/benchmark_plan.md` | `WBS 2.7` (`D08`) | Verification plan `L1–L4` & 5 skenario benchmark `BM-01..BM-05` vs `ESP32-C3` |
| `firmware/asm/` | `P-02`, `1.5`, `2.1–2.4` | Program uji `.asm`, `.hex`, `.in`, `.lst` (`hello`, `test_a_arith`, `test_b_ctrl_stack`, `test_e05_gpio`, `test_e06_timer`, `test_e07_irq_stack`) |
| `tb/` | `WBS 1.6`, `2.1–2.4` | `oc8051_defines.v`, `tb_8051_day1.v`, `tb_8051_day2.v` (self-checking + VCD + CSV dump) |
| `scripts/` | Otomasi | `asm8051.py`, `trace_checker.py`, `run_in_iic_osic.sh`, `run_baseline_all.sh`, `run_mutated_test_a.sh`, `run_repaired_regression.sh`, `run_day2_all.sh` |
| `traces/` | Waveform VCD | File `.vcd` & preset `.gtkw` untuk GTKWave / Surfer |
| `reports/` | Log, CSV & Word | Semua `*_sim.log`, `*_trace.csv`, `mutation.md`, `mut01_defect.diff`, serta laporan `.docx` Hari 1 & Hari 2 |
| `evidence/` | Gate H1 & H2 | Catatan bukti per sub-bab (`wbs_1_*`, `wbs_2_*`), `gate_h1_evidence_records.md`, `gate_h2_evidence_records.md`, dan gambar `evidence/figures/` |
| `manifest.yaml`, `tools.lock`, `signal_map.csv`, `LICENSE` | `P-01..P-05` | Kunci revisi core, daftar versi tools IIC-OSIC, peta 61 sinyal observasi, dan lisensi |

### Laporan Word (.docx)
- **Hari 1:** [`reports/Laporan_Evidence_WBS_Hari1_8051_YokeMikal.docx`](reports/Laporan_Evidence_WBS_Hari1_8051_YokeMikal.docx)
- **Hari 2:** [`reports/Laporan_Evidence_WBS_Hari2_8051_RV32_YokeMikal.docx`](reports/Laporan_Evidence_WBS_Hari2_8051_RV32_YokeMikal.docx)

---

## 3. Prasyarat Lingkungan (WSL2 Ubuntu + Docker IIC-OSIC)

- **WSL2 Ubuntu** dengan Docker Desktop aktif (WSL2 integration enabled).
- Image Docker: `hpretl/iic-osic-tools:latest` (`iverilog 14.0`, `vvp 14.0`, `verilator 5.052`, `yosys 0.70`, `gtkwave`, `surfer 0.7.0`, `python 3.12.3`).
- Lokasi workspace default di WSL: `~/eda/designs/8051_bootcamp` (di-mount ke `/foss/designs/8051_bootcamp` di dalam container).

---

## 4. Panduan Menjalankan Simulasi & Verifikasi Langkah demi Langkah

Masuk ke direktori proyek di WSL Ubuntu:
```bash
cd ~/eda/designs/8051_bootcamp
```

### A. Simulasi & Verifikasi Hari 1 (`Gate H1`: Test A, Test B, Test C)

1. **Jalankan simulasi baseline (`hello`, `test_a`, `test_b`) di Docker IIC-OSIC:**
   ```bash
   bash scripts/run_in_iic_osic.sh scripts/run_baseline_all.sh
   ```
   Output yang diharapkan: `[FINISH] PASS` untuk ketiga simulasi (`RAM[30h]=08h` pada `test_a`, `RAM[30h]=0Ch` dan `RAM[40h]=16h` pada `test_b`).

2. **Jalankan Golden ISA Trace Checker (`WBS 1.7`):**
   ```bash
   python3 scripts/trace_checker.py --rom firmware/asm/test_a_arith.in --trace reports/test_a_trace.csv
   python3 scripts/trace_checker.py --rom firmware/asm/test_b_ctrl_stack.in --trace reports/test_b_trace.csv
   ```
   Output: `PASS` dengan `0 divergences` pada seluruh batas instruksi (`12/12` step untuk `test_a`, `20/20` step untuk `test_b`).

3. **Uji Mutation Testing (`Gate H1 Test C` / `E08`):**
   - Rekaman kegagalan defect `MUT-01` (`rtl_mutation/oc8051_alu.v:162`, `add3 = 3'b001`) sudah tersimpan di `reports/test_a_mutated_sim.log` (`[FINISH] FAIL errors=5`) dan `traces/test_a_mutated.vcd`.
   - Untuk menguji `trace_checker.py` mendeteksi *first divergence* pada trace yang cacat tersebut:
     ```bash
     python3 scripts/trace_checker.py --rom firmware/asm/test_a_arith.in --trace reports/test_a_mutated_trace.csv
     ```
     *(Akan berhenti di Step 1 `PC=0002h ADD A,#03h` dengan mismatch `ACC: exp=08 obs=09`.)*
   - Untuk menjalankan regresi pada `rtl_mutation/` yang sudah diperbaiki:
     ```bash
     bash scripts/run_in_iic_osic.sh scripts/run_repaired_regression.sh
     ```

### B. Simulasi Hari 2 (`E05` GPIO, `E06` Timer `÷12`, `E07` Interrupt & Stack)

```bash
bash scripts/run_in_iic_osic.sh scripts/run_day2_all.sh
```
Output yang diharapkan:
- `e05_gpio`: `[FINISH] PASS` (`P0_o=a9`, `P3_o=3c`, `RAM[30h]=a5` dari pin `P2`, `RAM[31h]=c3` dari pin `P0`)
- `e06_timer`: `[FINISH] PASS` (`pres_ow=10`, `tf0_ovf=2`, Overflow #1 @ Cyc 63 & #2 @ Cyc 111 = delta tepat 48 clock, `RAM[30..32]=fc,fc,02`)
- `e07_irq`: `[FINISH] PASS` (`intr=1 vec=0b`, `ack=1`, `max_sp=0b`, `reti=1`, `SP=07`, `int_proc=0`, `RAM[30..32]=01,55,80`)

### C. Assemble Ulang Firmware (Opsional)
```bash
python3 scripts/asm8051.py firmware/asm/test_a_arith.asm -o firmware/asm/test_a_arith.hex
```

---

## 5. Cara Membuka Waveform & Sinyal Penting di GTKWave / Surfer

```bash
# Hari 1
gtkwave traces/test_a.vcd traces/test_a.gtkw &
gtkwave traces/test_b.vcd &
gtkwave traces/test_a_mutated.vcd &

# Hari 2
gtkwave traces/e05_gpio.vcd &
gtkwave traces/e06_timer.vcd &
gtkwave traces/e07_irq.vcd &
```

**Sinyal utama untuk diamati (`tb_8051_day1` / `tb_8051_day2`):**
- **`test_a.vcd`:** `dbg_booted`, `dbg_cur_pc`, `dbg_op1`, `dbg_acc`, `dbg_psw`, `dbg_ram30` (`08`), `dbg_ram34` (`C0`), `p1_o` (`7F`).
- **`test_b.vcd`:** `dbg_cur_pc`, `dbg_r2` (`04->00`), `dbg_sp` (`07->09->07`), `dbg_stk08` (`11`), `dbg_stk09` (`00`), `dbg_ram30` (`0C`), `dbg_ram31` (`16`), `dbg_ram40` (`16`).
- **`e05_gpio.vcd`:** `dbg_cur_pc`, `dbg_rmw`, `p0_o` (`FF->5A->5B->59->A9`), `p0_i` (`C3`), `dbg_ram30` (`A5`), `dbg_ram31` (`C3`).
- **`e06_timer.vcd`:** `dbg_pres_ow`, `dbg_tr0`, `dbg_tf0`, `dbg_tl0` (`FC->FD->FE->FF->FC`), `dbg_th0` (`FC`).
- **`e07_irq.vcd`:** `dbg_pc_reg`, `dbg_intr`, `dbg_int_vec` (`0B`), `dbg_int_ack`, `dbg_int_proc`, `dbg_reti`, `dbg_sp` (`07->0B->07`), `dbg_acc`, `dbg_psw`, `dbg_ram31` (`55`), `dbg_ram32` (`80`).

---

## 6. Ringkasan Status Gate & Rencana Lanjutan

- **Gate H1 (Hari 1):** **PASS** (`E01–E04`, `E08`, `D01–D05`).
- **Gate H2 (Hari 2):** **PASS** (`E05–E07`, `D06–D08`, Gap Matrix `8051 <-> EduRV-32`).
- **Next Action Backlog (`M1–M5`):** Rekonstruksi core `EduRV-32` (`RV32I` single-cycle -> 5-stage pipeline + M-mode CSRs) -> integrasi SoC `YEKVO32` sesuai `spec/yekvo32_architecture.md` & `spec/mmio_contract.csv` -> benchmark `BM-01..BM-05` melawan `ESP32-C3`.
