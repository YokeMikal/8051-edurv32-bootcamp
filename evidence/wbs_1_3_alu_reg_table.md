# WBS 1.3 / E02 — ALU, Flags, Write Enable & Register Update Table

**Sumber RTL:** `oc8051_alu.v`, `oc8051_alu_src_sel.v`, `oc8051_psw.v`, `oc8051_acc.v`  
**Sumber Bukti:** Simulasi `test_a` (`reports/test_a_trace.csv`, `reports/test_a_sim.log`, `reports/test_a_trace_check.md`)

---

## 1. Cara Kerja Jalur ALU & Write Enable di `oc8051`

1. **Mux Operand (`oc8051_alu_src_sel1`):** Saat instruksi di-decode pada cycle `N`, operand didaftarkan (`op1_r`, `op2_r`, `op3_r`) lalu di-mux ke `src1`, `src2`, `src3` pada cycle `N+1`.
2. **Adder/Subtractor 3-Stage (`oc8051_alu.v`):**
   - `OC8051_ALU_ADD` (`4'b0001`) memecah penjumlahan menjadi `add4` (bit `[3:0]` → menghasilkan **`desAc = add4[4]`**), `add8` (bit `[6:4]`), dan `addc` (bit `[7]` → menghasilkan **`desCy = addc[1]`** dan **`desOv = addc[1] ^ add8[3]`**).
   - `OC8051_ALU_SUB` (`4'b0010`) memakai borrow-in `srcCy` (`PSW.CY`) dan menghasilkan **`desCy = !subc[1]`**, **`desAc = !sub4[4]`**, **`desOv = !subc[1] ^ !sub8[3]`**.
3. **Write Enable & Pipeline Timing:**
   - Hasil ALU `des_acc`, `desCy`, `desAc`, `desOv` tersedia secara kombinasional pada cycle `N+1` dan di-latch ke register arsitektural (`ACC`, `PSW`, atau `RAM/SFR`) pada rising clock menuju cycle **`N+2`**.
   - `wr_sfr` mengaktifkan tulis ke `ACC` (`WRS_ACC1` / `WRS_ACC2`) atau `DPTR` (`WRS_DPTR`).
   - `psw_set` memilih flag mana yang disimpan (`00=NOT`, `01=CY`, `10=CY+OV`, `11=CY+OV+AC`).
   - **Catatan perangkat keras `PSW[0]` (Parity `P`):** Di `oc8051_acc.v:97`, `p = ^acc` dihitung dari sinyal *kombinasional* `acc` (sebelum flip-flop), sehingga bit `PSW[0]` sudah mencerminkan paritas hasil instruksi berikutnya satu cycle lebih awal sebelum `ACC` terdaftar. Bit `PSW[7:1]` (`CY, AC, F0, RS1, RS0, OV`) selalu ter-latch sinkron pada `cyc_d + 2`.

---

## 2. Tabel Pembaruan Register & Flag Terukur (`test_a_trace.csv`)

| Step | Decode → Commit Cyc | `PC` | Instruksi | `alu_op` (cyc `N+1`) | Operand (`src1`, `src2`, `srcCy`) | Expected (`ACC`, `PSW[7:1]`, `RAM`) | Observed (`ACC`, `PSW`, `RAM`) | Penjelasan Flag |
|---:|---:|:---:|---|---|---|---:|---:|---|
| 0 | 12 → 14 | `0000h` | `MOV A, #05h` | `00` (NOP) | `src1=05h, src2=00h` | `A=05h`, `PSW[7:1]=00h` | `A=05h`, `PSW=01h*` | `ACC=05h` (`P` fisik=0, `01h` krn lookahead `08h`) |
| 1 | 13 → 15 | `0002h` | `ADD A, #03h` | `01` (ADD) | `src1=03h, src2=05h, Cy=0` | `A=08h`, `PSW[7:1]=00h` | `A=08h`, `PSW=01h` | `05h+03h=08h` (genap 1 bit → `P=1`, `CY=AC=OV=0`) |
| 2 | 14 → 16 | `0004h` | `MOV 30h, A` | `00` (NOP) | `wr_addr=30h, wr_dat=08h` | `RAM[30h]=08h` | **`RAM[30h]=08h`** | **Gate H1 Test A tercapai (`RAM[30h] == 08h`)** |
| 3 | 15 → 17 | `0006h` | `INC A` | `0E` (INC) | `src1=08h, src2=00h` | `A=09h`, `PSW[7:1]=00h` | `A=09h`, `PSW=00h` | `INC A` tidak mengubah `CY/AC/OV`; `09h` (2 bit `1`) → `P=0` |
| 4 | 16 → 18 | `0007h` | `MOV 31h, A` | `00` (NOP) | `wr_addr=31h, wr_dat=09h` | `RAM[31h]=09h` | `RAM[31h]=09h` | Store `09h` ke RAM `31h` |
| 5 | 17 → 19 | `0009h` | `SUBB A, #02h` | `02` (SUB) | `src1=09h, src2=02h, Cy=0` | `A=07h`, `PSW[7:1]=00h` | `A=07h`, `PSW=01h` | `09h-02h-0=07h` (`CY=0, AC=0, OV=0`, 3 bit `1` → `P=1`) |
| 6 | 18 → 20 | `000Bh` | `MOV 32h, A` | `00` (NOP) | `wr_addr=32h, wr_dat=07h` | `RAM[32h]=07h` | `RAM[32h]=07h` | Store `07h` ke RAM `32h` |
| 7 | 19 → 21 | `000Dh` | `ADD A, #0FCh` | `01` (ADD) | `src1=FCh, src2=07h, Cy=0` | `A=03h`, `PSW=C0h` (`CY=1, AC=1, OV=0, P=0`) | `A=03h`, `PSW=C0h` | `7+12=19>15` (`AC=1`); `07h+FCh=103h` (`CY=1`); signed `+7 + (-4) = +3` (`OV=0`) |
| 8 | 20 → 22 | `000Fh` | `MOV 33h, A` | `00` (NOP) | `wr_addr=33h, wr_dat=03h` | `RAM[33h]=03h` | `RAM[33h]=03h` | Store `03h` ke RAM `33h` |
| 9 | 21 → 23 | `0011h` | `MOV 34h, PSW` | `00` (NOP) | `wr_addr=34h, wr_dat=C0h` | `RAM[34h]=C0h` | **`RAM[34h]=C0h`** | Membuktikan seluruh byte `PSW=C0h` terbaca & tersimpan akurat |

**Verdict E02 (MOV / ADD / INC / SUBB / Store):** `PASS` — Seluruh nilai `ACC`, flag `PSW`, dan `RAM[30h..34h]` cocok 100% antara golden ISA model dan RTL DUT.
