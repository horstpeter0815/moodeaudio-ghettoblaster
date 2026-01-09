#!/bin/bash
################################################################################
#
# Regression test runner (Mac):
# - SD config sanity (Waveshare forum solution checks)
# - Optional Docker-based simulations (display + network) if Docker is running
#
# Usage (from home):
#   cd ~/moodeaudio-cursor && ./tools/test/regression-sd-and-sim.sh
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== REGRESSION: SD + SIM ==="
echo ""

echo "[1/3] SD display config sanity..."
bash "$PROJECT_ROOT/tools/test/forum-solution-simulation.sh"
echo ""

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "[2/3] Docker VM display simulation..."
  bash "$PROJECT_ROOT/tools/test/forum-solution-vm-simulation.sh" || true
  echo ""

  echo "[3/3] Docker network simulation tests..."
  bash "$PROJECT_ROOT/tools/test/network-simulation-tests.sh" || true
  echo ""
else
  echo "[2/3] Docker not available/running - skipping VM and network simulations."
  echo "      Install/start Docker Desktop to enable full regression suite."
fi

echo "=== DONE ==="

