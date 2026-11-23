#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$PROJ_DIR/scripts/run_day1_sim.sh" "$PROJ_DIR/rtl_mutation" "test_a" \
  "$PROJ_DIR/firmware/asm/test_a_arith.in" \
  "$PROJ_DIR/traces/test_a_mutated.vcd" \
  "$PROJ_DIR/reports/test_a_mutated_trace.csv" \
  "$PROJ_DIR/reports/test_a_mutated_sim.log"
