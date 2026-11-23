# Spec / D06 — Proposal Arsitektur MCU Minimal YEKVO32 (Berbasis EduRV-32 RV32I)

**Deliverable ID:** `D06` (WBS 2.6)  
**Target:** Spesifikasi baseline SoC mikrokontroler 32-bit pasca-bootcamp (Milestone M1–M3 pada `/home/yokemikal/eda/designs/edurv32_repo`)  
**Catatan Kepatuhan Gate H2:** Peta memori di bawah adalah **rancangan eksplisit milik YEKVO32** — **TIDAK** menyalin alamat internal ESP32-C3 (`0x3FC8_xxxx` / `0x6000_xxxx`).

---

## 1. Gambaran Arsitektur Blok `yekvo32_mcu_top`

Sistem minimal **YEKVO32** terdiri atas 1 bus master (CPU `EduRV-32` RV32I M-mode) yang terhubung melalui *interconnect* sinkron sederhana (`valid / ready / we / wstrb / addr / wdata / rdata`) ke 2 blok memori dan 4 blok peripheral MMIO:

1. **`u_cpu` (`edurv32_core` — RV32I + CSR M-mode):**
   - Mendukung instruksi dasar RV32I (`37` instruksi + `ECALL`/`EBREAK`/`MRET`/`CSRRW`/`CSRRS`) dan CSR minimum (`mstatus`, `mie`, `mip`, `mtvec`, `mepc`, `mcause`, `mcycle`).
   - Antarmuka bus: *Instruction Fetch Port* (`imem_*` ke Boot ROM / SRAM) dan *Data/MMIO Port* (`dmem_*` dengan `wstrb[3:0]` byte-enable).
2. **`u_bus` (`yekvo32_bus_matrix`):**
   - Dekoder alamat kombinasional berbasis `addr[31:28]` + `addr[15:12]` (1-cycle response untuk SRAM & MMIO, tanpa wait-state kompleks).
   - Mengembalikan bus error trap bila alamat tidak terdaftar (*unmapped access*).
3. **`u_rom` (`boot_rom` — 16 KB, `0x0000_0000 – 0x0000_3FFF`):**
   - Read/Execute only; menyimpan reset vector (`0x0000_0000`), `crt0.S` startup, `.rodata`, dan kode program (`text`). Write ditolak (`ignore / bus fault`).
4. **`u_sram` (`data_sram` — 32 KB, `0x2000_0000 – 0x2000_7FFF`):**
   - Read/Write/Execute dengan dukungan `wstrb[3:0]` untuk `SB`/`SH`/`SW`; menyimpan `.data`, `.bss`, dan stack (inisialisasi `sp = 0x2000_8000` tumbuh ke bawah).
5. **Blok Peripheral MMIO (`0x4000_0000 – 0x4000_3FFF`, masing-masing slot 4 KB):**
   - **`u_gpio` (`0x4000_0000`):** 32-bit GPIO dengan register atomik `SET` dan `CLR` (menghindari kebutuhan *hardware bit-addressing* ala 8051).
   - **`u_timer` (`0x4000_1000`):** Timer 32-bit dengan prescaler 16-bit dapat diprogram, mode *auto-reload* / *free-run*, dan sinyal `irq_timer`.
   - **`u_uart` (`0x4000_2000`):** UART 8N1 dengan FIFO TX/RX minimal (status `TX_FULL`, `RX_VALID`), pembagi baud rate, dan `irq_uart`.
   - **`u_irq` (`0x4000_3000` — CLINT-lite / Interrupt Controller):** Menggabungkan sumber interrupt (`Timer0`, `UART0`, `GPIO_EXT`), mendukung `ENABLE`, `PENDING`, dan mekanisme `CLAIM` sebelum menyalurkan `ext_irq` / `timer_irq` ke `u_cpu`.

---

## 2. Draft Memory Map Eksplisit YEKVO32 (Bukan Alamat ESP32-C3)

| Region | Base Address | End Address | Ukuran | Atribut | Isi & Catatan Kontrak |
|---|---|---|---|---|---|
| **BOOT_ROM / IROM** | `0x0000_0000` | `0x0000_3FFF` | 16 KB | `RX` | Reset PC = `0x0000_0000`, `crt0.S`, teks kode C, `.rodata` |
| *Reserved Hole 0* | `0x0000_4000` | `0x1FFF_FFFF` | — | Unmapped | Tidak diakses (bus fault / return 0) |
| **ONCHIP_SRAM** | `0x2000_0000` | `0x2000_7FFF` | 32 KB | `RWX` | `.data`, `.bss`, heap, dan stack (`sp` mulai dari `0x2000_8000`) |
| *Reserved Hole 1* | `0x2000_8000` | `0x3FFF_FFFF` | — | Unmapped | Cadangan ekspansi SRAM |
| **GPIO0 (MMIO)** | `0x4000_0000` | `0x4000_0FFF` | 4 KB | `RW (32-bit)` | Register arah, input pin, output latch, set/clear atomik |
| **TIMER0 (MMIO)** | `0x4000_1000` | `0x4000_1FFF` | 4 KB | `RW (32-bit)` | Kontrol timer, prescaler, auto-reload `LOAD`, `COUNT`, flag `STATUS` |
| **UART0 (MMIO)** | `0x4000_2000` | `0x4000_2FFF` | 4 KB | `RW (32-bit)` | Data TX/RX, status FIFO, kontrol, pembagi baud rate |
| **IRQ_CTRL (MMIO)** | `0x4000_3000` | `0x4000_3FFF` | 4 KB | `RW (32-bit)` | Masking enable, status pending, claim ID, threshold |

*(Catatan: Rincian register lengkap tiap offset ada di deliverable D07 `spec/mmio_contract.csv`.)*

---

## 3. Kebutuhan Firmware Startup (`crt0.S`) & API HAL Minimal

```c
/* Contoh header API HAL minimal YEKVO32 (memakai spec/mmio_contract.csv) */
#define GPIO0_BASE   0x40000000u
#define TIMER0_BASE  0x40001000u
#define UART0_BASE   0x40002000u
#define IRQ0_BASE    0x40003000u

#define REG32(addr)  (*(volatile uint32_t *)(addr))

static inline void gpio_set_mask(uint32_t mask)   { REG32(GPIO0_BASE + 0x0Cu) = mask; }
static inline void gpio_clear_mask(uint32_t mask) { REG32(GPIO0_BASE + 0x10u) = mask; }
static inline uint32_t gpio_read_pins(void)       { return REG32(GPIO0_BASE + 0x08u); }
```

**Urutan wajib `crt0.S` saat Reset (`0x0000_0000`):**
1. Inisialisasi `sp = 0x2000_8000` dan kosongkan register `x1..x31`.
2. Set `mtvec` ke alamat `trap_entry` (aligned 4-byte, mode direct).
3. Salin seksi `.data` dari ROM (`_sidata`) ke SRAM (`_sdata.._edata`).
4. Nolkan seksi `.bss` di SRAM (`_sbss.._ebss`).
5. Panggil `main()`, dan pasang infinite loop pengaman jika `main()` return.
