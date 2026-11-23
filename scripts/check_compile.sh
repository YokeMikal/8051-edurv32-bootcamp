#!/usr/bin/env bash
set -u

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$PROJ_DIR/reports/baseline_compile.log"
RTL="$PROJ_DIR/rtl_reference/rtl/verilog"
BENCH="$PROJ_DIR/rtl_reference/bench/verilog"
SIMRUN="$PROJ_DIR/rtl_reference/sim/rtl_sim/run"

{
  echo "=== Test 1: iverilog with -I rtl/verilog (raw default defines) ==="
  iverilog -g2005 -I "$RTL" -I "$BENCH" -s oc8051_top -o /tmp/check_t1.vvp \
    "$RTL/oc8051_top.v" \
    "$RTL/oc8051_alu_src_sel.v" \
    "$RTL/oc8051_alu.v" \
    "$RTL/oc8051_decoder.v" \
    "$RTL/oc8051_divide.v" \
    "$RTL/oc8051_multiply.v" \
    "$RTL/oc8051_memory_interface.v" \
    "$RTL/oc8051_ram_top.v" \
    "$RTL/oc8051_acc.v" \
    "$RTL/oc8051_comp.v" \
    "$RTL/oc8051_sp.v" \
    "$RTL/oc8051_dptr.v" \
    "$RTL/oc8051_cy_select.v" \
    "$RTL/oc8051_psw.v" \
    "$RTL/oc8051_indi_addr.v" \
    "$RTL/oc8051_ports.v" \
    "$RTL/oc8051_b_register.v" \
    "$RTL/oc8051_uart.v" \
    "$RTL/oc8051_int.v" \
    "$RTL/oc8051_tc.v" \
    "$RTL/oc8051_tc2.v" \
    "$RTL/oc8051_icache.v" \
    "$RTL/oc8051_wb_iinterface.v" \
    "$RTL/oc8051_sfr.v" \
    "$RTL/oc8051_rom.v" \
    "$RTL/oc8051_ram_256x8_two_bist.v" \
    "$RTL/oc8051_ram_64x32_dual_bist.v" \
    "$RTL/oc8051_cache_ram.v" 2>&1
  echo "EXIT_T1=$?"

  echo ""
  echo "=== Test 2: iverilog with -I sim/rtl_sim/run -I rtl/verilog + oc8051_tb ==="
  iverilog -g2005 -I "$SIMRUN" -I "$RTL" -I "$BENCH" -s oc8051_tb -o /tmp/check_t2.vvp \
    "$BENCH/oc8051_tb.v" \
    "$BENCH/oc8051_xram.v" \
    "$BENCH/oc8051_uart_test.v" \
    "$BENCH/oc8051_xrom.v" \
    "$RTL/oc8051_top.v" \
    "$RTL/oc8051_alu_src_sel.v" \
    "$RTL/oc8051_alu.v" \
    "$RTL/oc8051_decoder.v" \
    "$RTL/oc8051_divide.v" \
    "$RTL/oc8051_multiply.v" \
    "$RTL/oc8051_memory_interface.v" \
    "$RTL/oc8051_ram_top.v" \
    "$RTL/oc8051_acc.v" \
    "$RTL/oc8051_comp.v" \
    "$RTL/oc8051_sp.v" \
    "$RTL/oc8051_dptr.v" \
    "$RTL/oc8051_cy_select.v" \
    "$RTL/oc8051_psw.v" \
    "$RTL/oc8051_indi_addr.v" \
    "$RTL/oc8051_ports.v" \
    "$RTL/oc8051_b_register.v" \
    "$RTL/oc8051_uart.v" \
    "$RTL/oc8051_int.v" \
    "$RTL/oc8051_tc.v" \
    "$RTL/oc8051_tc2.v" \
    "$RTL/oc8051_icache.v" \
    "$RTL/oc8051_wb_iinterface.v" \
    "$RTL/oc8051_sfr.v" \
    "$RTL/oc8051_rom.v" \
    "$RTL/oc8051_ram_256x8_two_bist.v" \
    "$RTL/oc8051_ram_64x32_dual_bist.v" \
    "$RTL/oc8051_cache_ram.v" 2>&1
  echo "EXIT_T2=$?"
} > "$LOG"

cat "$LOG"
