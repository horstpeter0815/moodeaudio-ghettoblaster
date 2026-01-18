#!/bin/bash
#
# Docker simulation bootstrapper:
# - Makes custom scripts available at /usr/local/bin (services reference this path)
# - Makes custom unit files visible to systemd (services are mounted under /lib/systemd/system/custom)
# - Starts a minimal X server (Xvfb) so X11-dependent units can run
# - Starts a small set of "interesting" units to generate evidence
#
# Output is written to /var/log/sim/custom-bootstrap.log (mounted to host by compose)
#

set -euo pipefail

LOG_FILE="/var/log/sim/custom-bootstrap.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== custom-bootstrap starting ==="

CUSTOM_SCRIPTS_DIR="/usr/local/bin/custom"
CUSTOM_UNITS_DIR="/lib/systemd/system/custom"

log "Custom scripts dir: $CUSTOM_SCRIPTS_DIR"
log "Custom units dir:   $CUSTOM_UNITS_DIR"

# 1) Expose scripts at /usr/local/bin/<name> because unit files refer to that path.
if [ -d "$CUSTOM_SCRIPTS_DIR" ]; then
  for f in "$CUSTOM_SCRIPTS_DIR"/*; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    target="/usr/local/bin/$base"
    if [ ! -e "$target" ]; then
      ln -s "$f" "$target" || true
      log "Linked script: $target -> $f"
    fi
  done
else
  log "WARN: $CUSTOM_SCRIPTS_DIR does not exist"
fi

# 2) Expose unit files to systemd.
# NOTE: In some containerized-systemd setups, unit discovery via symlinks can be
# flaky (especially when the source is a bind-mounted directory). To keep the
# simulation deterministic, copy the unit file contents into /etc/systemd/system.
if [ -d "$CUSTOM_UNITS_DIR" ]; then
  for u in "$CUSTOM_UNITS_DIR"/*.service; do
    [ -e "$u" ] || continue
    base="$(basename "$u")"
    target="/etc/systemd/system/$base"
    # Always refresh to match repo state
    if cp -f "$u" "$target" 2>/dev/null; then
      log "Installed unit: $target (from $u)"
    else
      log "WARN: failed to install unit $base from $u"
    fi
  done
else
  log "WARN: $CUSTOM_UNITS_DIR does not exist"
fi

log "Reloading systemd daemon"
systemctl daemon-reload || true

# 3) Start a basic X server so xrandr/xdpyinfo checks have something to talk to.
# We run Xvfb permissively (-ac) to avoid Xauthority headaches in the container.
if ! pgrep -x Xvfb >/dev/null 2>&1; then
  log "Starting Xvfb :0 (1280x400x24)"
  nohup Xvfb :0 -screen 0 1280x400x24 -ac +extension RANDR +render -noreset >/var/log/sim/xvfb.log 2>&1 &
  sleep 2
else
  log "Xvfb already running"
fi

# 4) Start a few services to generate evidence.
# We start them directly (rather than enable) so they run in this boot.
WANTED_UNITS=(
  "xserver-ready.service"
  "localdisplay.service"
  "boot-debug-logger.service"
  "fix-network-ip.service"
  "moode-db-smoketest.service"
  "moode-web-smoke.service"
)

for unit in "${WANTED_UNITS[@]}"; do
  log "Starting unit: $unit"
  systemctl start --no-block "$unit" 2>&1 | tee -a "$LOG_FILE" || log "WARN: failed to start $unit"
done

log "=== unit status snapshot (interesting) ==="
systemctl status "${WANTED_UNITS[@]}" --no-pager 2>&1 | tee -a "$LOG_FILE" || true

log "=== failed units ==="
systemctl --failed --no-pager 2>&1 | tee -a "$LOG_FILE" || true

log "=== custom-bootstrap complete ==="
exit 0

