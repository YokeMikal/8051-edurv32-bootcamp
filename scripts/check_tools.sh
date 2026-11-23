#!/usr/bin/env bash
set -u

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$PROJ_DIR/tools.lock"
{
  echo "# IIC-OSIC-TOOLS Lockfile"
  echo "timestamp_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "docker_image: hpretl/iic-osic-tools:latest"
  echo ""
  echo "[iverilog]"
  iverilog -V 2>&1 | head -n 1
  echo ""
  echo "[vvp]"
  vvp -V 2>&1 | head -n 1
  echo ""
  echo "[verilator]"
  verilator --version 2>&1
  echo ""
  echo "[yosys]"
  yosys -V 2>&1
  echo ""
  echo "[verible-verilog-lint]"
  verible-verilog-lint --version 2>&1 | head -n 1
  echo ""
  echo "[gtkwave]"
  gtkwave --version 2>&1 | head -n 1
  echo ""
  echo "[surfer]"
  surfer --version 2>&1 || echo "surfer --version exited non-zero"
  echo ""
  echo "[python3]"
  python3 --version 2>&1
} > "$OUT"

cat "$OUT"
