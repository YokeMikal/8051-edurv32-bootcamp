# WBS 2.3 & 2.4 / E07 — Interrupt Vector 000Bh, RETI, Context Save/Restore & Stack Budget

**Experiment ID:** `E07` (WBS 2.3 & WBS 2.4)  
**Sumber RTL:** `rtl_reference/rtl/verilog/oc8051_int.v`, `oc8051_memory_interface.v` (lines 645–656, 875–891), `oc8051_sp.v`  
**Firmware Uji:** `firmware/asm/test_e07_irq_stack.asm` (`hex_sha256: 6edf4f1be5265f4531c15e6780761d922e2439ba6655d062ab564112b13c4f5d`)  
**Bukti Simulasi:** `reports/e07_irq_sim.log`, `reports/e07_irq_trace.csv`, `traces/e07_irq.vcd`

---

## 1. Alur Perangkat Keras Interrupt & `RETI` di `oc8051`

1. **Pemicuan & Arbitrasi (`oc8051_int.v:141-155, 295-341`):**
   - Timer 0 overflow (`TL0: FFh → FCh`) mengaktifkan `tcon_tf0 = 1`.
   - Karena `IE = 82h` (`EA=1`, `ET0=1`), bit `int_src[1]` aktif → `oc8051_int1` menaikkan **`intr = 1`**, mengeset **`int_vec = 0Bh`**, dan mencatat `int_proc = 1`, `int_dept = 1`.
2. **Injeksi Sintetis `LCALL 000Bh` (`oc8051_memory_interface.v:647-650`):**
   - Hardware mengganti opcode berikutnya dengan instruksi sintetis `LCALL 00<int_vec>` (`12 00 0B`), mendorong alamat kembali `PC` (`0047h`) ke stack (`SP: 07h → 08h → 09h`), dan membangkitkan pulsa **`int_ack = 1`** yang otomatis meng-clear `tcon_tf0` (`oc8051_int.v:232`).
   - *Catatan Penting Polaritas Pin:* `int0_i` & `int1_i` pada `oc8051_int.v:249` adalah **active-low** (`!(ie0)`), sehingga testbench wajib menahan keduanya pada **`1'b1`** ketika idle agar interrupt eksternal palsu tidak terpicu saat `EA=1`.
3. **Kontrol Kembali (`RETI`, opcode `32h`):**
   - Menarik return PC (`0047h`) dari stack (`SP: 09h → 08h → 07h`) dan menaikkan sinyal `reti = 1` menuju `oc8051_int1` (`oc8051_int.v:291-294`) agar **`int_proc` kembali ke `0`** dan `int_dept` turun ke `0`.

---

## 2. Trace Aktual Interrupt Entry, Context Clobber Check, Stack & RETI (`e07_irq_trace.csv`)

Sebelum interrupt, program utama mengeset penanda konteks: **`ACC = 55h`**, **`PSW = 80h` (`CY = 1`)**, **`SP = 07h`**, lalu memutar di loop `0047h: JNB RAM20.0, wait_isr` setelah menyalakan Timer 0 (`TH0=TL0=FDh`, `IE=82h`).

| Cycle | Time | `pc_reg` | `op1` | `intr` / `vec` / `ack` | `proc` / `reti` | `SP` | `STK[08..0B]` | `ACC` | `PSW` | Peristiwa Teknis |
|---:|---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| 63 | 1340 ns | `004Ah` | `F5` | `0 / 00 / 0` | `0 / 0` | `07h` | `00,00,00,00` | `55h` | `80h` | Program utama menunggu di `wait_isr` (`0047h`) |
| **64** | **1360 ns** | `004Ah` | `F5` | **`1 / 0B / 0`** | **`1 / 0`** | `07h` | `00,00,00,00` | `55h` | `80h` | **IRQ Timer 0 terbit (`intr=1`, `vec=0Bh`)** |
| 65 | 1380 ns | `0047h` | **`12`** | `0 / 00 / 0` | `1 / 0` | `07h` | `00,00,00,00` | `55h` | `80h` | Hardware injeksi sintetis **`LCALL 000Bh`** (`op=12h`) |
| 66 | 1400 ns | `0047h` | `F5` | `0 / 00 / 0` | `1 / 0` | **`08h`** | `00,00,00,00` | `55h` | `80h` | Push `PCL = 47h` ke stack `08h` |
| 67 | 1420 ns | `0047h` | `F5` | `0 / 00 / 1` | `1 / 0` | **`09h`** | **`47,00,00,00`** | `55h` | `80h` | Push `PCH = 00h` ke `09h` + **`ack=1`** auto-clear `TF0` |
| **68** | **1440 ns** | **`000Bh`** | `02` | `0 / 00 / 0` | `1 / 0` | `09h` | `47,00,00,00` | `55h` | `80h` | Masuk **vektor IRQ `000Bh`** (`LJMP 0060h`) |
| 72 | 1520 ns | **`0060h`** | `C0` | `0 / 00 / 0` | `1 / 0` | `09h` | `47,00,00,00` | `55h` | `80h` | Awal `isr_t0`: `PUSH ACC` |
| 74–75 | 1560–1580 ns | `0062→0064` | `C0→74` | `0 / 00 / 0` | `1 / 0` | `0A→` **`0Bh`** | `47,00,` **`55,80`** | `55h` | `80h` | `PUSH ACC` & `PUSH PSW` (`max_sp=0Bh`, konteks `55h/80h` aman!) |
| 77–80 | 1620–1680 ns | `0068→006F` | `05..D2` | `0 / 00 / 0` | `1 / 0` | `0Bh` | `47,00,55,80` | **`ABh`** | **`01h`** | ISR merusak `ACC=ABh` & **`CY=0`**, set `RAM[30h]=01h`, `P0=A5h`, stop TR0 |
| 82 | 1720 ns | `0073h` | `D0` | `0 / 00 / 0` | `1 / 0` | **`0Ah`** | `47,00,55,80` | `ABh` | `01h` | `RAM[20h]=01h`; jalankan `POP PSW` & `POP ACC` |
| 83–84 | 1740–1760 ns | `0075→0076` | **`32`** | `0 / 00 / 0` | `1 /` **`1`** | `09→08h` | `47,00,55,80` | **`55h`** | **`80h`** | **`RETI` (`op=32h`)** memicu `reti=1`; `ACC=55h` & `PSW=80h` pulih! |
| **85** | **1780 ns** | `0076h` | `00` | `0 / 00 / 0` | **`0`** `/ 0` | **`07h`** | `47,00,55,80` | `55h` | `80h` | `SP` pulih ke **`07h`** & `int_proc` kembali **`0`** |
| 88 | 1840 ns | **`0047h`** | `30` | `0 / 00 / 0` | `0 / 0` | `07h` | `47,00,55,80` | `55h` | `80h` | Kembali tepat ke `0047h` dan keluar loop karena `RAM20.0 == 1` |
| 93–94 | 1940–1960 ns | `004F→0052` | `75→80` | `0 / 00 / 0` | `0 / 0` | `07h` | `47,00,55,80` | `55h` | `80h` | Menangkap **`RAM[31h]=55h`** dan **`RAM[32h]=80h`** (komplit!) |

---

## 3. WBS 2.4 — Analisis Nesting, Stack Budget & Kebijakan Reset

1. **Asumsi & Dukungan Nesting di RTL (`oc8051_int.v:109-119, 295-322`):**
   - `oc8051_int` menyediakan array 2-slot (`isrc[1:0]`, `int_lev[1:0]`, `int_dept`) untuk tepat **2 level prioritas interrupt**:
     - Saat ISR Level-0 (`IP[x]=0`) aktif (`int_proc=1, cur_lev=0`), hanya sumber dengan **`IP[y]=1`** (`il1=1`) dan `EA=1` yang dapat melakukan *preemption* (nesting ke `int_dept=2`).
     - Saat ISR Level-1 aktif (`cur_lev=1`), preemption lebih lanjut diblokir oleh `!cur_lev`.
   - *Best-practice ISR:* Bila preemption tidak dibutuhkan, biarkan semua bit `IP = 00h` (single-level IRQ) atau matikan `CLR EA` di awal ISR.
2. **Perhitungan Stack Budget (Batas Aman RAM Internal 256 Byte):**
   - Pointer awal setelah reset: **`SP = 07h`** (Register Bank 0 memakai `00h–07h`).
   - Ruang aman Lower DATA Stack (`08h–7Fh`) tanpa menimpa data/bit-area (`20h–2Fh`) & scratchpad (`30h–7Fh`): **`08h–1Fh` = 24 byte** (atau hingga `120 byte` jika Upper IDATA `80h–FFh` dialokasikan khusus stack).
   - Biaya stack terukur pada `E07`:
     - Hardware vector entry (`LCALL 000Bh`): **2 byte** (`SP: 07h → 09h`).
     - Software context save minimum (`PUSH ACC` + `PUSH PSW`): **2 byte** (`SP: 09h → 0Bh`, `max_sp = 0Bh`). *(Jika ISR juga memakai register `R0..R7` atau `B/DPTR` tanpa ganti bank `RS1:RS0`, tambah 2–3 byte lagi).*
   - Rumus worst-case stack budget pada `oc8051`:
     $$\text{Stack}_{\max} = 2\cdot D_{\text{call}} + 2\cdot N_{\text{nested\_irq}} + \sum_{k=1}^{N_{\text{nested\_irq}}} C_{\text{ctx},k}$$
     Dengan `D_call = 4` (8 byte), `N_nested_irq = 2` level prioritas, dan `C_ctx = 4 byte/ISR` (`ACC, PSW, DPL, DPH`), total budget terburuk = `8 + 4 + 8 = 20 byte` (`SP max = 07h + 14h = 1Bh < 20h`), sehingga dijamin tidak bertabrakan dengan area bit-addressable `20h–2Fh`.
3. **Reset Policy (`wb_rst_i`):**
   - `wb_rst_i = 1` secara asinkron mengosongkan `int_proc=0`, `int_dept=0`, `int_vec=0`, `IE=00h`, `IP=00h`, `TCON=00h`, memulihkan `SP=07h`, dan memulai eksekusi ulang dari `0000h`.

**Verdict E07 (`e07_irq_sim.log`):** `[FINISH] PASS` (`intr=1`, `ack=1`, `reti=1`, `max_sp=0Bh`, `SP=07h`, `int_proc=0`, `stk08..0b=47,00,55,80`, `RAM[30..32]=01,55,80`).
