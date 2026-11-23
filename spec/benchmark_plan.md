# Spec / D08 — Rencana Verifikasi & Benchmark Fungsional YEKVO32 vs ESP32-C3

**Deliverable ID:** `D08` (WBS 2.7)  
**Berlaku untuk:** Rekonstruksi **EduRV-32 (`M1–M4`)** & Benchmark komparatif terhadap **ESP32-C3**.

---

## 1. Rencana Verifikasi RTL & HW/SW (Verification Plan)

Mengadopsi pelajaran nyata dari Hari 1 & Hari 2 (terutama kebutuhan golden trace checker dan uji mutasi `PASS → FAIL → PASS`):

### A. Lapisan Verifikasi Berjenjang
| Level | Target | Metodologi & Oracle | Kriteria Lulus (`PASS`) |
|---|---|---|---|
| **L1 — Unit & Protocol** | ALU, Decoder RV32I, Bus Matrix, GPIO/Timer/UART/IRQ | Self-checking SV/Verilog TB + SVA bus handshake (`valid` stabil sampai `ready`) | 0 error lint (`verilator --lint-only -Wall`, `verible`), 0 inferred latch (`yosys check`) |
| **L2 — ISA & Golden Trace** | CPU `EduRV-32` (`riscv-tests` RV32I + program C `crt0`) | Ekstraksi commit trace (`cycle, pc, instr, rd, val, mem_addr, trap`) vs model referensi ISA RV32I (**Spike / Python RV32I oracle**) | **0 divergence** pada setiap instruction boundary (`trace_checker`) |
| **L3 — Peripheral & ISR** | MMIO contract `D07` (`GPIO0`, `TIMER0`, `UART0`, `IRQ_CTRL`) | Directed firmware tests (`gpio_atomics`, `timer_reload`, `uart_loopback`, `irq_context`) + cek stack `mret` | `GPIO_IN/OUT/SET/CLR` presisi, `TIM_COUNT` bebas drift, `mepc/mstatus` & `SP` pulih 100% |
| **L4 — Mutation Testing** | Ketajaman testbench (`E08`-style gate per Bab) | Injeksi minimal 1 defect terisolasi tiap milestone (contoh: salah sign-extend immediate `I-type`, salah decode write `GPIO_CLR`, gagal restore `MIE` di `mret`) | Siklus **`PASS → FAIL (first divergence terdeteksi) → PASS`** |

### B. Batas Hardware/Design Spec (HW/HDS Constraints)
- **Single-Clock Domain (Baseline M1–M3):** Semua modul berjalan pada domain clock tunggal `clk_sys` (`50 MHz` simulasi / target FPGA) dengan reset sinkron atau reset asinkron ter-synchronisasi (*reset bridge*).
- **Alignment & MMIO Access:** Akses MMIO wajib berukuran **32-bit word-aligned** (`addr[1:0] == 2'b00`); akses byte/unaligned ke area MMIO menghasilkan error flag atau terlarang secara kontrak SW.
- **No Uninitialized X-State in Regfile/CSR:** `x0` selalu bernilai `0`; seluruh register MMIO memiliki nilai reset eksplisit sesuai `spec/mmio_contract.csv`.

---

## 2. Rencana Benchmark Fungsional YEKVO32 vs ESP32-C3 (WBS 2.7 / Milestone M4)

### Batas Klaim Ilmiah & Terminologi (Sesuai Seksi 1 & 8 YEKVO)
Benchmark terhadap **ESP32-C3** (RISC-V 32-bit komersial) **HANYA** membandingkan fitur & workload terpilih secara terukur (metrik siklus clock, latensi relatif dalam clock maupun waktu nyata pada frekuensi terdefinisi, serta ukuran kode terkompilasi). **BUKAN** klaim kesetaraan RF Wi-Fi/BLE, konsumsi daya ultra-low-power, fitur enkripsi hardware/secure boot, target clock 160 MHz, ataupun kompatibilitas biner penuh ESP-IDF.

### Kasus Uji & Protokol Pengukuran (5 Metrik Wajib)

| ID | Use Case Benchmark | Workload C Identik / Ekuivalen | Cara Pengukuran (YEKVO32 RTL vs ESP32-C3) | Metrik yang Dicatat |
|---|---|---|---|---|
| **BM-01** | **GPIO Toggle Latency** | Loop C: set & clear 1 pin GPIO via `GPIO_SET`/`GPIO_CLR` (`0x4000_000C/10`) sebanyak 1000 iterasi | RTL: ukur selisih `mcycle` & edge `gpio_o` di VCD; ESP32-C3: ukur via `GPIO.out_w1ts` / logic analyzer atau `esp_cpu_get_cycle_count()` | Cycles per toggle, frekuensi toggle efektif, rasio clock/edge |
| **BM-02** | **Timer Tick & Overflow Jitter** | Konfigurasi `TIMER0` auto-reload 1 ms (`TIM_PRESCALE` + `TIM_LOAD`), catat delta timestamp antar 100 overflow | RTL: inspeksi CSV antar event `TIM_STATUS[0]` naik; ESP32-C3: `gptimer` hardware timer capture | Deviasi cycle (`min/max/std jitter`), error 0-cycle pada auto-reload |
| **BM-03** | **Interrupt Entry & Exit Latency** | Timer / GPIO IRQ memicu toggling pin debug di baris pertama ISR; bandingkan waktu request sampai pin naik (`entry`) & kembali via `mret` (`exit`) | RTL: hitung delta cycle dari `irq_pending` naik sampai instruksi pertama ISR + `mret`; ESP32-C3: logic analyzer / cycle counter | Interrupt latency (cycles & ns) + cost context save/restore (`64 B` frame) |
| **BM-04** | **UART Throughput & Polling vs IRQ** | Kirim payload 256 byte `"YEKVO32_BENCH..."` @ 115200 baud | Verifikasi bit timing `txd_o` (`UART_BAUDDIV`), CPU utilization selama TX | Error baud rate (`%`), throughput efektif (bytes/s), idle CPU cycles |
| **BM-05** | **Code Size Footprint** | Kompilasi program benchmark yang sama (`-Os` vs `-O2`) memakai `riscv32-unknown-elf-gcc` vs toolchain ESP-IDF | Jalankan `riscv32-unknown-elf-size` untuk membandingkan `.text`, `.data`, `.bss` | Ukuran `.text` (byte) untuk `RV32I` vs `RV32IMC` (ESP32-C3) |
