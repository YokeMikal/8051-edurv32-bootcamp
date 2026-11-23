# WBS 2.2 / E06 — Timer/Counter Tick, Prescaler ÷12, Auto-Reload & Overflow Trace

**Experiment ID:** `E06` (WBS 2.2)  
**Sumber RTL:** `rtl_reference/rtl/verilog/oc8051_tc.v`, `oc8051_sfr.v` (lines 708–720)  
**Firmware Uji:** `firmware/asm/test_e06_timer.asm` (`hex_sha256: e993582121e48e9c033b217f3bbdbf0d3d38ad3e5661aad9b77148c847ad5a53`)  
**Bukti Simulasi:** `reports/e06_timer_sim.log`, `reports/e06_timer_trace.csv`, `traces/e06_timer.vcd`

---

## 1. Arsitektur Prescaler & Mode 2 Auto-Reload di `oc8051`

1. **Prescaler Sistem Divide-by-12 (`oc8051_sfr.v:708-720`):**
   - Register `prescaler[3:0]` menghitung `0..11` (12 siklus `wb_clk_i` per *machine cycle* klasik 8051) dan membangkitkan pulsa 1-clock **`pres_ow = 1`** saat `prescaler == 4'b1011`.
2. **Kondisi Increment Timer 0 (`oc8051_tc.v:111`):**
   ```verilog
   assign tc0_add = (tr0 & (!tmod[3] | !ie0) & ((!tmod[2] & pres_ow) | (tmod[2] & !t0 & t0_buff)));
   ```
   - Dengan `TMOD = 02h` (`GATE=0`, `C/T#=0`, `M1:M0 = 10` = Mode 2), `TL0` bertambah +1 setiap `pres_ow == 1` selama `TR0 == 1`.
3. **Logika Auto-Reload & Flag Overflow (`oc8051_tc.v:157-169`):**
   - Ketika `tc0_add == 1` dan `tl0 == 8'hFF`, dalam **1 clock yang sama** `tl0 <= th0` (auto-reload ke `FCh`) dan output internal `tf0 <= 1'b1`.
   - Satu clock berikutnya, modul `oc8051_int1` (`oc8051_int.v:230-231`) mendeteksi rising edge `!(tf0_buff) & tf0` dan mengunci bit status **`TCON.5` (`TF0`, bit `8Dh`) = 1**.

---

## 2. Trace Aktual Tick Prescaler, Reload & Dual Overflow (`e06_timer_trace.csv`)

Konfigurasi awal firmware: `TMOD = 02h`, `TH0 = FCh`, `TL0 = FCh`, `TR0 = 1` (aktif mulai Cycle 20). Karena `TL0` mulai di `FCh`, dibutuhkan tepat **4 tick `pres_ow`** (`FC → FD → FE → FF → overflow+reload FC`) per overflow (`4 × 12 = 48` clock!).

| Cycle | Time | `pres` | `pres_ow` | `TR0` | `TF0` | `TL0` | `P0_o` | `RAM[30..32]` | Kejadian Aktual di RTL |
|---:|---:|---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| 16 | 400.00 ns | `3` | `0` | `0` | `0` | `FCh` | `FFh` | `00,00,00` | Inisialisasi `TMOD=02h`, `TH0=FCh`, `TL0=FCh` selesai |
| 20 | 480.00 ns | `7` | `0` | **`1`** | `0` | `FCh` | `FFh` | `00,00,00` | `SETB TR0` mengaktifkan Timer 0; masuk loop polling `JNB TF0` |
| 25 → 26 | 580→600 ns | `0→1` | **`1`** | `1` | `0` | `FC→FD` | `FFh` | `00,00,00` | Tick `pres_ow` #1 → `TL0` naik ke `FDh` |
| 37 → 38 | 820→840 ns | `0→1` | **`1`** | `1` | `0` | `FD→FE` | `FFh` | `00,00,00` | Tick `pres_ow` #2 (+12 cyc) → `TL0` naik ke `FEh` |
| 49 → 50 | 1060→1080 ns | `0→1` | **`1`** | `1` | `0` | `FE→FF` | `FFh` | `00,00,00` | Tick `pres_ow` #3 (+12 cyc) → `TL0` mencapai `FFh` |
| 61 → 62 | 1300→1320 ns | `0→1` | **`1`** | `1` | `0` | **`FF→FC`** | `FFh` | `00,00,00` | Tick `pres_ow` #4 (+12 cyc): `TL0` **auto-reload ke `TH0 = FCh`**! |
| **63** | **1340.00 ns** | `2` | `0` | `1` | **`1`** | `FCh` | `FFh` | `00,00,00` | **`Overflow #1`** — `TCON=30h` (`TF0=1` di-latch oleh `oc8051_int1`) |
| 69 | 1460.00 ns | `8` | `0` | `1` | `1` | `FCh` | `FFh` | **`FC,00,00`** | Polling keluar → `MOV 30h, TL0` menangkap nilai reload **`FCh`**! |
| 70 | 1480.00 ns | `9` | `0` | `1` | **`0`** | `FCh` | `FFh` | `FC,00,00` | `CLR TF0` menghapus flag `TCON.5` |
| 72 | 1520.00 ns | `11` | `0` | `1` | `0` | `FCh` | **`01h`** | `FC,00,00` | `MOV P0, #01h` menandakan overflow #1 terproses sebelum tick berikut! |
| 73 → 74 | 1540→1560 ns | `0→1` | **`1`** | `1` | `0` | `FC→FD` | `01h` | `FC,00,00` | Siklus #2 dimulai (+12 cyc dari tick `61`): `TL0` naik ke `FDh` |
| 85 → 86 | 1780→1800 ns | `0→1` | **`1`** | `1` | `0` | `FD→FE` | `01h` | `FC,00,00` | +12 cyc → `FEh` |
| 97 → 98 | 2020→2040 ns | `0→1` | **`1`** | `1` | `0` | `FE→FF` | `01h` | `FC,00,00` | +12 cyc → `FFh` |
| 109 → 110 | 2260→2280 ns | `0→1` | **`1`** | `1` | `0` | **`FF→FC`** | `01h` | `FC,00,00` | +12 cyc: `TL0` auto-reload ke `TH0 = FCh` |
| **111** | **2300.00 ns** | `2` | `0` | `1` | **`1`** | `FCh` | `01h` | `FC,00,00` | **`Overflow #2`** (`TCON=30h`, tepat **48 clock = 960 ns** setelah Overflow #1!) |
| 116 | 2400.00 ns | `7` | `0` | **`0`** | `1` | `FCh` | `01h` | `FC,00,00` | `CLR TR0` menghentikan Timer 0 |
| 118–122 | 2440–2520 ns | `9..1` | `0` | `0` | `0` | `FCh` | **`02h`** | **`FC,FC,02`** | `RAM[31h]=FCh`, `RAM[32h]=02h`, `P0_o=02h`, lalu `P1_o=7Fh` di Cycle 123 |

**Bukti Periode Eksak:** Selisih Overflow #1 (Cycle 63, `1340 ns`) ke Overflow #2 (Cycle 111, `2300 ns`) adalah tepat **`48` clock cycles = `4 × 12` clock prescaler = `960.00 ns`** (zero jitter).  
**Verdict E06 (`e06_timer_sim.log`):** `[FINISH] PASS` (`pres_ow=10`, `tf0_ovf=2`, `RAM[30..32]=FC,FC,02`, `P0_o=02h`, `TR0=0`).
