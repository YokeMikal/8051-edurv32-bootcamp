# WBS 2.1 / E05 — MMIO/SFR Decode & Trace GPIO (`oc8051_ports.v`)

**Experiment ID:** `E05` (WBS 2.1)  
**Sumber RTL:** `rtl_reference/rtl/verilog/oc8051_ports.v`, `oc8051_sfr.v`, `oc8051_decoder.v`, `oc8051_top.v`  
**Firmware Uji:** `firmware/asm/test_e05_gpio.asm` (`hex_sha256: 8733b1ab9676c9dbea78ce62083c6d94fe4d6cacf5a09c34064670f73f696ec6`)  
**Bukti Simulasi:** `reports/e05_gpio_sim.log`, `reports/e05_gpio_trace.csv`, `traces/e05_gpio.vcd`

---

## 1. Mekanisme Dekode SFR & Read-Modify-Write GPIO pada `oc8051`

1. **Peta Alamat SFR Port (`oc8051_defines.v`):**
   - Byte-addressable: `P0 = 80h`, `P1 = 90h`, `P2 = A0h`, `P3 = B0h` (seluruhnya reset ke `FFh` pada `wb_rst_i == 1`).
   - Bit-addressable: `P0.0..P0.7` (`80h..87h`), `P1.0..P1.7` (`90h..97h`), `P2.0..P2.7` (`A0h..A7h`), `P3.0..P3.7` (`B0h..B7h`).
2. **Pemisahan Akses Direct SFR (`!wr_ind`):**
   - Di `oc8051_top.v:609`, write enable ke `oc8051_sfr1` aktif hanya bila `.we(wr_o && !wr_ind)`. Karena itu menulis direct ke alamat `80h/90h/A0h/B0h` memperbarui output latch `p0_out..p3_out` di `oc8051_ports1` dan tidak menulis ke upper IDATA RAM.
3. **Kontrak HW/SW Kritis — Pin Read (`rmw = 0`) vs Output Latch Read (`rmw = 1`):**
   - Pada `oc8051_ports.v:119`, mux pembacaan port didefinisikan sebagai:
     ```verilog
     assign p0_data = rmw ? p0_out : p0_in;
     ```
   - Saat instruksi baca biasa (`MOV A, P0` / `MOV A, P2`), decoder men-set **`rmw = 0`**, sehingga CPU membaca kondisi fisik **pin eksternal `pX_in`**.
   - Saat instruksi Read-Modify-Write (`SETB P0.0`, `CLR P0.1`, `XRL P0, #0F0h`), decoder men-set **`rmw = 1`**, sehingga ALU memodifikasi isi **output latch `p0_out`** dan tidak terpengaruh tegangan pin eksternal `p0_i`.

---

## 2. Trace Aktual Simulasi GPIO (`reports/e05_gpio_trace.csv`)

Kondisi stimulus eksternal pada `tb_8051_day2.v`: `p0_i = C3h` (sengaja berbeda dari nilai latch output), `p2_i = A5h`.

| Cycle | Time | `cur_pc` | `op1` | Instruksi | `rmw` | `P0_o` (Latch) | `P3_o` | `ACC` | `RAM[30h]` | `RAM[31h]` | Efek & Pembuktian RTL |
|---:|---:|:---:|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|---|
| 12 | 320.00 ns | `0000h` | `75` | `MOV P0, #5Ah` | `0` | `FFh` | `FFh` | `00h` | `00h` | `00h` | Decode tulis byte direct ke SFR `80h` |
| 14 | 360.00 ns | `0005h` | `C2` | *(commit `MOV P0`)* / `CLR P0.1` | `1` | **`5Ah`** | `FFh` | `00h` | `00h` | `00h` | Latch `p0_o` berubah `FFh → 5Ah` |
| 16 | 400.00 ns | `0007h` | `63` | *(commit `SETB P0.0`)* / `XRL P0,#F0h` | `1` | **`5Bh`** | `FFh` | `00h` | `00h` | `00h` | Bit write `wr_bit=1` (bit `80h`) set bit-0 → `5Bh` |
| 18 | 440.00 ns | `000Ah` | `75` | *(commit `CLR P0.1`)* | `1` | **`59h`** | `FFh` | `00h` | `00h` | `00h` | Bit clear (bit `81h`) clear bit-1 → `59h` |
| 20 | 480.00 ns | `000Dh` | `E5` | *(commit `XRL P0,#F0h`)* / `MOV A,P2` | `0` | **`A9h`** | `FFh` | `00h` | `00h` | `00h` | `rmw=1` membaca latch `59h` → `59h XOR F0h = A9h` (bukan `C3h XOR F0h`)! |
| 21 | 500.00 ns | `000Fh` | `F5` | *(commit `MOV P3,#3Ch`)* | `0` | `A9h` | **`3Ch`** | `00h` | `00h` | `00h` | Port 3 latch `p3_o` berubah ke `3Ch` |
| 22 | 520.00 ns | `0011h` | `E5` | *(commit `MOV A,P2`)* / `MOV A,P0` | `0` | `A9h` | `3Ch` | **`A5h`** | `00h` | `00h` | `rmw=0` membaca pin eksternal `p2_i = A5h` |
| 23 | 540.00 ns | `0013h` | `F5` | `MOV 30h, A` | `0` | `A9h` | `3Ch` | `A5h` | **`A5h`** | `00h` | Simpan hasil baca `P2` ke `RAM[30h]` |
| 24 | 560.00 ns | `0015h` | `75` | *(commit `MOV A,P0`)* | `0` | `A9h` | `3Ch` | **`C3h`** | `A5h` | `00h` | `rmw=0` membaca **pin eksternal `p0_i = C3h`**, latch tetap `A9h`! |
| 25 | 580.00 ns | `0018h` | `80` | `MOV 31h, A` | `0` | `A9h` | `3Ch` | `C3h` | `A5h` | **`C3h`** | Simpan hasil baca `P0` ke `RAM[31h]` |
| 26 | 600.00 ns | `001Ah` | `00` | *(commit `MOV P1,#7Fh`)* | `0` | `A9h` | `3Ch` | `C3h` | `A5h` | `C3h` | `P1_o = 7Fh` (sentinel selesai) |

**Verdict E05 (`e05_gpio_sim.log`):** `[FINISH] PASS` (`cyc=31`, `P0_o=A9h`, `P3_o=3Ch`, `RAM[30h]=A5h`, `RAM[31h]=C3h`, zero errors).
