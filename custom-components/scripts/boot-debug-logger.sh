#!/bin/bash
#
# Boot Debug Logger wrapper expected by custom-components/services/boot-debug-logger.service
#
# Modes:
# - start:   run a one-shot snapshot (delegates to simple-boot-logger.sh)
# - monitor: periodic snapshots (default every 60s)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIMPLE_LOGGER="$SCRIPT_DIR/simple-boot-logger.sh"

MODE="${1:-start}"

log() {
  echo "[boot-debug-logger] $*" | systemd-cat -t boot-debug-logger 2>/dev/null || true
}

if [ ! -x "$SIMPLE_LOGGER" ]; then
  echo "ERROR: simple logger not found or not executable: $SIMPLE_LOGGER" >&2
  exit 1
fi

case "$MODE" in
  start)
    log "start: running one-shot snapshot"
    exec "$SIMPLE_LOGGER"
    ;;

  monitor)
    INTERVAL="${BOOT_DEBUG_INTERVAL_SECONDS:-60}"
    log "monitor: starting periodic snapshots every ${INTERVAL}s"
    while true; do
      "$SIMPLE_LOGGER" || true
      sleep "$INTERVAL"
    done
    ;;

  *)
    echo "Usage: $0 {start|monitor}" >&2
    exit 2
    ;;
esac

