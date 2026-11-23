#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="$PROJ_DIR/rtl_reference/rtl/verilog"

bash "$PROJ_DIR/scripts/run_day1_sim.sh" "$RTL" "hello" \
  "$PROJ_DIR/firmware/asm/hello.in" \
  "$PROJ_DIR/traces/hello.vcd" \
  "$PROJ_DIR/reports/hello_trace.csv" \
  "$PROJ_DIR/reports/hello_sim.log"

bash "$PROJ_DIR/scripts/run_day1_sim.sh" "$RTL" "test_a" \
  "$PROJ_DIR/firmware/asm/test_a_arith.in" \
  "$PROJ_DIR/traces/test_a.vcd" \
  "$PROJ_DIR/reports/test_a_trace.csv" \
  "$PROJ_DIR/reports/test_a_sim.log"

bash "$PROJ_DIR/scripts/run_day1_sim.sh" "$RTL" "test_b" \
  "$PROJ_DIR/firmware/asm/test_b_ctrl_stack.in" \
  "$PROJ_DIR/traces/test_b.vcd" \
  "$PROJ_DIR/reports/test_b_trace.csv" \
  "$PROJ_DIR/reports/test_b_sim.log"
