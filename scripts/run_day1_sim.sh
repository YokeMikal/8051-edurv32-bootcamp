#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RTL_DIR="${1:?rtl_dir required}"
TEST_NAME="${2:?test_name required}"
ROM_IN="${3:?rom_in required}"
VCD_OUT="${4:?vcd_out required}"
TRACE_CSV="${5:?trace_csv required}"
LOG_OUT="${6:?log_out required}"

SIM_BIN="/tmp/sim_${TEST_NAME}.vvp"

mkdir -p "$(dirname "$VCD_OUT")" "$(dirname "$TRACE_CSV")" "$(dirname "$LOG_OUT")"

iverilog -g2005 -Wall \
  -I "$PROJ_DIR/tb" \
  -I "$RTL_DIR" \
  -s tb_8051_day1 \
  -o "$SIM_BIN" \
  "$PROJ_DIR/tb/tb_8051_day1.v" \
  "$RTL_DIR/oc8051_top.v" \
  "$RTL_DIR/oc8051_alu_src_sel.v" \
  "$RTL_DIR/oc8051_alu.v" \
  "$RTL_DIR/oc8051_decoder.v" \
  "$RTL_DIR/oc8051_divide.v" \
  "$RTL_DIR/oc8051_multiply.v" \
  "$RTL_DIR/oc8051_memory_interface.v" \
  "$RTL_DIR/oc8051_ram_top.v" \
  "$RTL_DIR/oc8051_acc.v" \
  "$RTL_DIR/oc8051_comp.v" \
  "$RTL_DIR/oc8051_sp.v" \
  "$RTL_DIR/oc8051_dptr.v" \
  "$RTL_DIR/oc8051_cy_select.v" \
  "$RTL_DIR/oc8051_psw.v" \
  "$RTL_DIR/oc8051_indi_addr.v" \
  "$RTL_DIR/oc8051_ports.v" \
  "$RTL_DIR/oc8051_b_register.v" \
  "$RTL_DIR/oc8051_uart.v" \
  "$RTL_DIR/oc8051_int.v" \
  "$RTL_DIR/oc8051_tc.v" \
  "$RTL_DIR/oc8051_tc2.v" \
  "$RTL_DIR/oc8051_icache.v" \
  "$RTL_DIR/oc8051_wb_iinterface.v" \
  "$RTL_DIR/oc8051_sfr.v" \
  "$RTL_DIR/oc8051_rom.v" \
  "$RTL_DIR/oc8051_ram_256x8_two_bist.v" \
  "$RTL_DIR/oc8051_ram_64x32_dual_bist.v" \
  "$RTL_DIR/oc8051_cache_ram.v" > "$LOG_OUT" 2>&1

vvp "$SIM_BIN" \
  "+TEST_NAME=$TEST_NAME" \
  "+ROM_FILE=$ROM_IN" \
  "+VCD_FILE=$VCD_OUT" \
  "+TRACE_FILE=$TRACE_CSV" >> "$LOG_OUT" 2>&1

echo "=== $TEST_NAME ($LOG_OUT) ==="
tail -n 25 "$LOG_OUT"
