#!/bin/bash
################################################################################
#
# fix-xinitrc-display.sh (Waveshare 7.9" forum solution helper)
#
# This script is intended to be copied onto bootfs and executed on the Pi once
# (or on demand) to apply the "forum solution" alignment between:
# - moOde DB setting hdmi_scn_orient
# - X11 rotation via xrandr (HDMI-1/HDMI-2)
# - Chromium window size expectations
#
# It is SAFE to run multiple times.
#
################################################################################

set -e

LOG_FILE="/var/log/fix-xinitrc-display.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

log "=== fix-xinitrc-display.sh start ==="

# Ensure we can talk to X11 if present
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Forum-solution SCREENSIZE swap marker (used by repo test)
# SCREENSIZE is computed from framebuffer (Portrait -> Landscape swap)
SCREENSIZE="$(fbset -s 2>/dev/null | awk '$1 == "geometry" { print $3","$2 }')"
log "SCREENSIZE(raw fb swap)=${SCREENSIZE}"

# IMPORTANT:
# moOde's stock `.xinitrc` rotates HDMI only when `hdmi_scn_orient=portrait`.
# For the Waveshare 7.9" (native portrait 400x1280), we want moOde to consider
# the panel "portrait" so it will apply the rotate-left step to achieve 1280x400.
#
# (We keep it as a best-effort; if moodeutl isn't present yet, skip.)
if command -v moodeutl >/dev/null 2>&1; then
  log "Setting hdmi_scn_orient=portrait in moOde DB"
  moodeutl -i "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';" 2>/dev/null || true
else
  log "moodeutl not found; skipping hdmi_scn_orient update"
fi

# Rotate X11 output to match Waveshare landscape
# (Repo test expects this string pattern)
if command -v xrandr >/dev/null 2>&1; then
  # Prefer HDMI-2 (Pi 5 usually uses HDMI-A-2); fallback to HDMI-1
  log "Applying xrandr rotation (try HDMI-2 then HDMI-1)"
  xrandr --output HDMI-2 --rotate normal 2>/dev/null || true
  xrandr --output HDMI-2 --mode 400x1280 2>/dev/null || true
  xrandr --output HDMI-2 --rotate left 2>/dev/null || \
  (xrandr --output HDMI-1 --rotate normal 2>/dev/null || true; \
   xrandr --output HDMI-1 --mode 400x1280 2>/dev/null || true; \
   xrandr --output HDMI-1 --rotate left 2>/dev/null || true)
else
  log "xrandr not available; skipping X11 rotation"
fi

log "=== fix-xinitrc-display.sh done ==="

