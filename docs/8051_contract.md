# WBS 1.4 / D02 — Kontrak Memori, Address Decoder, SFR & Stack (`oc8051`)

**Dokumen Referensi RTL:** `oc8051_memory_interface.v`, `oc8051_ram_top.v`, `oc8051_sfr.v`, `oc8051_sp.v`, `oc8051_indi_addr.v`  
**Bukti Simulasi:** `reports/test_b_trace.csv`, `reports/test_b_sim.log`, `reports/test_b_trace_check.md`

---

## 1. Peta Ruang Alamat 8051 pada `oc8051`

| Ruang Alamat | Rentang | Mekanisme Akses ISA | Implementasi RTL di `oc8051` |
| :--- | :--- | :--- | :--- |
| **CODE (ROM)** | `0000h – FFFFh` (64 KB) | Fetch instruksi, `MOVC A,@A+DPTR/PC` | Eksternal via `wbi_adr_o[15:0]` & `wbi_dat_i[31:0]` saat `ea_in=0` (internal `oc8051_rom` nonaktif di config Day 1). |
| **DATA (Lower RAM)** | `00h – 7Fh` (128 B) | Direct (`MOV 30h,A`), Register `R0..R7`, Bit (`20h–2Fh`), Indirect `@Ri`, Stack | `oc8051_ram_top1.oc8051_idata.buff[0..127]`. Bank 0 `R0..R7` menempati `00h..07h`. |
| **IDATA (Upper RAM)** | `80h – FFh` (128 B) | **Hanya Indirect (`@Ri`) atau Stack (`PUSH/LCALL`)** | `oc8051_ram_top1.oc8051_idata.buff[128..255]`. |
| **SFR Space** | `80h – FFh` (128 B) | **Hanya Direct addressing** | `oc8051_sfr1` (alamat terdefinisi: `ACC`, `B`, `PSW`, `SP`, `DPL`, `DPH`, `P0..P3`, `TCON/TMOD/TL/TH`, `SCON/SBUF`, `IE/IP`). |
| **XDATA (Ext RAM)** | `0000h – FFFFh` (64 KB) | `MOVX A,@DPTR/@Ri`, `MOVX @DPTR/@Ri,A` | Bus Wishbone eksternal `wbd_adr_o[15:0]`, `wbd_dat_o`, `wbd_dat_i`, `wbd_we_o`, `wbd_stb_o`. |

---

## 2. Address Decoder RTL: Memisahkan Upper RAM vs SFR (`80h–FFh`)

Pada arsitektur 8051, alamat `80h–FFh` terbagi dua secara fisik (SFR vs Upper IDATA). Di `oc8051_top.v` & `oc8051_memory_interface.v`, dekode ini dilakukan secara eksplisit oleh sinyal `wr_ind` / `rd_ind`:

- **Sinyal `wr_ind` / `rd_ind`** bernilai `1` **hanya** jika `wr_sel` / `rd_sel` berasal dari akses indirect (`@Ri`) atau Stack (`SP`).
- **Write ke Internal RAM (`oc8051_top.v:425`):**
  ```verilog
  .wr(wr_o && (!wr_addr[7] || wr_ind))
  ```
  → Jika alamat `00h–7Fh` (`!wr_addr[7]`), selalu tulis ke RAM. Jika alamat `80h–FFh` (`wr_addr[7]==1`), **hanya tulis ke RAM bila `wr_ind == 1`** (indirect/stack).
- **Write ke SFR (`oc8051_top.v:609`):**
  ```verilog
  .we(wr_o && !wr_ind)
  ```
  → `oc8051_sfr1` hanya menerima write bila **bukan** akses indirect/stack (`!wr_ind`) dan `wr_addr` cocok dengan alamat SFR.
- **Read Mux (`oc8051_memory_interface.v:389`):**
  ```verilog
  if (rd_addr_r && !rd_ind) iram_out = sfr; else iram_out = in_ram;
  ```
  → Alamat `>= 80h` membaca `sfr` pada direct addressing dan membaca `in_ram` pada indirect/stack (`rd_ind=1`).

---

## 3. Daftar SFR Utama pada `oc8051_sfr.v`

| Alamat | Nama | Bit-Addressable | Reset (`oc8051_defines.v`) | Submodul RTL |
|---:|---|:---:|---:|---|
| `80h` | `P0` | Ya (`80h–87h`) | `FFh` | `oc8051_ports1` |
| `81h` | `SP` | Tidak | `07h` | `oc8051_sp1` |
| `82h / 83h` | `DPL / DPH` | Tidak | `00h / 00h` | `oc8051_dptr1` |
| `88h / 89h` | `TCON / TMOD` | `TCON` Ya | `00h / 00h` | `oc8051_int1` / `oc8051_tc1` |
| `8Ah–8Dh` | `TL0, TL1, TH0, TH1` | Tidak | `00h` | `oc8051_tc1` |
| `90h / A0h / B0h` | `P1 / P2 / P3` | Ya | `FFh` | `oc8051_ports1` |
| `98h / 99h` | `SCON / SBUF` | `SCON` Ya | `00h / 00h` | `oc8051_uatr1` |
| `A8h / B8h` | `IE / IP` | Ya | `00h / 00h` | `oc8051_int1` |
| `D0h` | `PSW` | Ya (`D0h–D7h`) | `00h` | `oc8051_psw1` (`{CY,AC,F0,RS1,RS0,OV,-,P}`) |
| `E0h` | `ACC` | Ya (`E0h–E7h`) | `00h` | `oc8051_acc1` |
| `F0h` | `B` | Ya (`F0h–F7h`) | `00h` | `oc8051_b_register` |

---

## 4. Bukti Stack Push/Pop & Indirect `@R0` (`test_b_trace.csv`)

Pada `firmware/asm/test_b_ctrl_stack.asm`, `LCALL add_ten` dieksekusi di `PC=000Eh` (panjang 3 byte, return address = `0011h`), diikuti `RET` di `0022h`, lalu `MOV R0,#40h` & `MOV @R0,A`:

| Cycle | Time | Event / Instruksi | `SP` | `wr_addr` | `wr_dat` | `RAM[08h]` | `RAM[09h]` | `RAM[40h]` | Keterangan RTL |
|---:|---:|---|---:|---:|---:|---:|---:|---:|---|
| 38 | 840.00 ns | Decode `LCALL 0020h` (`000Eh`) | `07h` | `00` | `00` | `00` | `00` | `00` | `LCALL` dimulai, `return PC = 0011h` |
| 39 | 860.00 ns | Push low byte (`PCL`) | **`08h`** | `08` | `11` | `00`→`11` | `00` | `00` | `sp_w = SP + 1 = 08h`, tulis `11h` ke RAM `08h` |
| 40 | 880.00 ns | Push high byte (`PCH`) | **`09h`** | `09` | `00` | `11` | `00`→`00` | `00` | `sp_w = 09h`, tulis `00h` ke RAM `09h`; `max_sp = 09h` |
| 42 | 920.00 ns | Masuk `add_ten` (`PC=0020h`) | `09h` | `02` | `00` | `11` | `00` | `00` | `ADD A, #0Ah` (`ACC: 0Ch → 16h`) |
| 43 | 940.00 ns | Decode `RET` (`0022h`) | `09h` | `04` | `0A` | `11` | `00` | `00` | Baca stack `RAM[09h]` (`PCH=00h`) |
| 44 | 960.00 ns | Pop cycle 1 | **`08h`** | `02` | `00` | `11` | `00` | `00` | `SP` turun ke `08h`, baca `RAM[08h]` (`PCL=11h`) |
| 45 | 980.00 ns | Pop cycle 2 | **`07h`** | `02` | `11` | `11` | `00` | `00` | `SP` kembali ke `07h`; `pc_buf` dipulihkan ke `0011h` |
| 48 | 1040.00 ns | Lanjut di `ret_point` (`0011h`) | `07h` | `00` | `00` | `11` | `00` | `00` | `MOV 31h, A` menulis `16h` ke `RAM[31h]` |
| 50 | 1080.00 ns | Decode `MOV @R0, A` (`0015h`) | `07h` | `00` | `40` | `11` | `00` | `00` | `oc8051_indi_addr1.buff[0]` menyediakan `ri = 40h` |
| 51 | 1100.00 ns | Tulis indirect (`wr_ind=1`) | `07h` | **`40`** | **`16`** | `11` | `00` | `00`→`16` | `ram_wr=1`, menulis `ACC=16h` ke alamat `40h` |
| 52 | 1120.00 ns | Commit `RAM[40h]` | `07h` | `90` | `7F` | `11` | `00` | **`16`** | Terbukti `RAM[40h] == 16h` |

**Verdict E04 (LCALL / RET & Stack):** `PASS` — `SP` bergerak `07h → 08h → 09h → 08h → 07h`, return address `0011h` tersimpan little-endian di stack (`RAM[08h]=11h`, `RAM[09h]=00h`), dan eksekusi kembali tepat ke `0011h`.
