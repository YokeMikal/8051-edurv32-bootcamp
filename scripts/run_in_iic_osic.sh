#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESIGNS_DIR="${DESIGNS:-$HOME/eda/designs}"
IMAGE="${IIC_OSIC_IMAGE:-hpretl/iic-osic-tools:latest}"
CONTAINER_PROJ="/foss/designs/$(basename "$PROJ_DIR")"

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker daemon is not running or not reachable from WSL."
  echo "[HINT]  Start Docker Desktop on Windows (with WSL2 integration enabled), then re-run."
  exit 1
fi

REQ="${1:-scripts/run_baseline_all.sh}"
if [ $# -gt 0 ]; then
  shift
fi

# Normalize relative script path inside project
REQ="${REQ#./}"
if [ ! -f "$PROJ_DIR/$REQ" ] && [ -f "$PROJ_DIR/scripts/$REQ" ]; then
  REQ="scripts/$REQ"
fi

if [ ! -f "$PROJ_DIR/$REQ" ]; then
  echo "[ERROR] Script not found in project: $PROJ_DIR/$REQ"
  exit 2
fi

exec docker run --rm \
  --security-opt seccomp=unconfined \
  -v "$DESIGNS_DIR:/foss/designs:rw" \
  -w "$CONTAINER_PROJ" \
  "$IMAGE" \
  --skip bash "$CONTAINER_PROJ/$REQ" "$@"
