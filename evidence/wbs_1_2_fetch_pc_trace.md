# WBS 1.2 / E01 — Fetch, ROM Address & PC Progression Trace

**Sumber Bukti:** Simulasi `test_a` (`reports/test_a_trace.csv`, `reports/test_a_sim.log`, `traces/test_a.vcd`)  
**Firmware:** `firmware/asm/test_a_arith.asm` (`firmware/asm/test_a_arith.in`)  
**Timescale Catatan:** `oc8051_timescale.v` adalah `` `timescale 1ns/10ps ``; periode clock `wb_clk_i` = **20 ns** (`#10` per half-cycle = 50 MHz). Pada log CSV, kolom `time_ns` (hasil `%0t`) bersatuan tick `10 ps` (`10000` = 100.00 ns; `32000` = 320.00 ns).

---

## 1. Mekanisme Fetch & PC di `oc8051_memory_interface.v`

1. **Reset Vector (`0000h`):** Saat `wb_rst_i == 1`, register `pc = 16'h0000`, `pc_buf = 16'h0000`, `op_pos = 3'h0`, `idat_cur = 32'h0`, `idat_old = 32'h0`, dan decoder berada pada `state = 2'b11`.
2. **External Pipelined ROM (`wbi_*`):** Karena `ea_in = 1'b0`, `ea_rom_sel = 1'b0`, sehingga core meminta word 32-bit `{rom[a+3], rom[a+2], rom[a+1], rom[a]}` melalui `wbi_adr_o`.
3. **Prefetch Window Warm-up (Cycle 1–11, `booted = 0`):**
   - Cycle 1–3: `oc8051_decoder1.state` turun `3 → 2 → 1 → 0` sehingga `rd` aktif (`rd = 1`) di Cycle 4.
   - Cycle 4–11: `op_pos` bergeser `0..3` dua kali sementara bus `wbi_*` mengisi `idat_old` (byte `0000h..0003h`) lalu `idat_cur` (byte `0004h..0007h`), dan `pc_buf` maju `0000h → 0004h → 0008h`.
   - Pada **Cycle 12 (`t = 320.00 ns`)**, `pc_buf = 0008h` dan `op_pos = 0` → `cur_pc = pc_buf - 8 + op_pos = 0000h`. Di sinilah instruksi pertama program pada reset vector `0000h` (`74 05` = `MOV A, #05h`) masuk ke `op1_n/op2_n`!
4. **Sliding Window & `op_length`:** Kombinasional `op_pos` (0..5) memilih 3 byte sekaligus `{op1, op2, op3}` melintasi batas `idat_old` dan `idat_cur`, sementara `op_length` (1, 2, atau 3) memajukan `op_pos` dan `pc` tepat sesuai panjang instruksi setiap kali `rd == 1`. Setiap kali `op_pos >= 3` dan `rd == 1`, `inc_pc` memicu fetch 4-byte berikutnya (`pc_buf + 4`).

---

## 2. Trace Aktual Reset + Fetch + PC Progression (`test_a_trace.csv`)

### Fase A: Reset & Prefetch Fill (`booted = 0`, Cycle 1–11)

| Cycle | Time | `booted` | `state` | `rd` | `wbi_adr` | `pc_buf` | `op_pos` | `op1` | Keterangan |
|---:|---:|:---:|---:|:---:|:---:|:---:|:---:|:---:|---|
| 1 | 100.00 ns | 0 | 3 | 0 | `0000h` | `0000h` | 0 | `00` | Cycle 1 pasca-reset (`wb_rst_i=0`), decoder FSM keluar dari reset |
| 4 | 160.00 ns | 0 | 0 | 1 | `0000h` | `0000h` | 0 | `00` | `rd` aktif; `wbi_dat_i` membawa ROM `[0000..0003]` |
| 7 | 220.00 ns | 0 | 0 | 1 | `0004h` | `0000h` | 3 | `00` | `inc_pc` aktif; prefetch pindah ke alamat `0004h` |
| 8 | 240.00 ns | 0 | 0 | 1 | `0004h` | `0004h` | 0 | `00` | `idat_cur` berisi ROM `[0000..0003]`, siap digeser ke `idat_old` |
| 11 | 300.00 ns | 0 | 0 | 1 | `0008h` | `0004h` | 3 | `00` | `inc_pc` aktif; ROM `[0004..0007]` masuk, `op3` sudah terlihat `05` |

### Fase B: Eksekusi Instruksi dari Reset Vector `0000h` (`booted = 1`, Cycle 12–23)

| Step | Decode Cyc | Time | `cur_pc` (`pc_reg`) | `op1` | `op2` | `op3` | `op_len` | `wbi_adr` | Instruksi |
|---:|---:|---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| 0 | 12 | 320.00 ns | **`0000h`** | `74` | `05` | `24` | **2** | `0008h` | `MOV A, #05h` (Reset Vector!) |
| 1 | 13 | 340.00 ns | **`0002h`** | `24` | `03` | `F5` | **2** | `0008h` | `ADD A, #03h` |
| 2 | 14 | 360.00 ns | **`0004h`** | `F5` | `30` | `04` | **2** | `000Ch` | `MOV 30h, A` |
| 3 | 15 | 380.00 ns | **`0006h`** | `04` | `F5` | `31` | **1** | `000Ch` | `INC A` |
| 4 | 16 | 400.00 ns | **`0007h`** | `F5` | `31` | `94` | **2** | `0010h` | `MOV 31h, A` |
| 5 | 17 | 420.00 ns | **`0009h`** | `94` | `02` | `F5` | **2** | `0010h` | `SUBB A, #02h` |
| 6 | 18 | 440.00 ns | **`000Bh`** | `F5` | `32` | `24` | **2** | `0014h` | `MOV 32h, A` |
| 7 | 19 | 460.00 ns | **`000Dh`** | `24` | `FC` | `F5` | **2** | `0014h` | `ADD A, #0FCh` |
| 8 | 20 | 480.00 ns | **`000Fh`** | `F5` | `33` | `85` | **2** | `0018h` | `MOV 33h, A` |
| 9 | 21 | 500.00 ns | **`0011h`** | `85` | `D0` | `34` | **3** | `0018h` | `MOV 34h, PSW` (`85 src dst`) |
| 10 | 22 | 520.00 ns | **`0014h`** | `75` | `90` | `7F` | **3** | `001Ch` | `MOV P1, #7Fh` |
| 11 | 23 | 540.00 ns | **`0017h`** | `80` | `FE` | `00` | **2** | `0020h` | `SJMP done (-2)` |

**Verdict E01 (Reset + Fetch):** `PASS` — Reset vector `0000h` tereksekusi tepat dengan panjang instruksi 1/2/3 byte akurat dan progresi `PC` linear (`0000→0002→0004→0006→0007→0009→000B→000D→000F→0011→0014→0017`).
