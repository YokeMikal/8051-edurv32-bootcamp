#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$PROJ_DIR/scripts/run_day1_sim.sh" "$PROJ_DIR/rtl_mutation" "test_a" \
  "$PROJ_DIR/firmware/asm/test_a_arith.in" \
  "$PROJ_DIR/traces/test_a_repaired.vcd" \
  "$PROJ_DIR/reports/test_a_repaired_trace.csv" \
  "$PROJ_DIR/reports/test_a_repaired_sim.log"

bash "$PROJ_DIR/scripts/run_day1_sim.sh" "$PROJ_DIR/rtl_mutation" "test_b" \
  "$PROJ_DIR/firmware/asm/test_b_ctrl_stack.in" \
  "$PROJ_DIR/traces/test_b_repaired.vcd" \
  "$PROJ_DIR/reports/test_b_repaired_trace.csv" \
  "$PROJ_DIR/reports/test_b_repaired_sim.log"
