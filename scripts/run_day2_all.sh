#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="$PROJ_DIR/rtl_reference/rtl/verilog"

bash "$PROJ_DIR/scripts/run_day2_sim.sh" "$RTL" "e05_gpio" \
  "$PROJ_DIR/firmware/asm/test_e05_gpio.in" \
  "$PROJ_DIR/traces/e05_gpio.vcd" \
  "$PROJ_DIR/reports/e05_gpio_trace.csv" \
  "$PROJ_DIR/reports/e05_gpio_sim.log"

bash "$PROJ_DIR/scripts/run_day2_sim.sh" "$RTL" "e06_timer" \
  "$PROJ_DIR/firmware/asm/test_e06_timer.in" \
  "$PROJ_DIR/traces/e06_timer.vcd" \
  "$PROJ_DIR/reports/e06_timer_trace.csv" \
  "$PROJ_DIR/reports/e06_timer_sim.log"

bash "$PROJ_DIR/scripts/run_day2_sim.sh" "$RTL" "e07_irq" \
  "$PROJ_DIR/firmware/asm/test_e07_irq_stack.in" \
  "$PROJ_DIR/traces/e07_irq.vcd" \
  "$PROJ_DIR/reports/e07_irq_trace.csv" \
  "$PROJ_DIR/reports/e07_irq_sim.log"
