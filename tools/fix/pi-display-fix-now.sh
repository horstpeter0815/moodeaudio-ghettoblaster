#!/bin/bash
################################################################################
#
# Pi display "cut off (top third only)" fix - run from Mac
#
# Symptoms:
# - Only top part of the UI visible, rest black
# - Usually X11 is 400x1280 while Chromium is forced to 1280x400
# - Often caused by rotating the wrong HDMI output (HDMI-1 vs HDMI-2)
#
# What this script does on the Pi:
# 1) Collects display state (hdmi_scn_orient, xdpyinfo, xrandr, chromium args)
# 2) Sets hdmi_scn_orient='portrait' (so moOde rotates HDMI in .xinitrc)
# 3) Patches /home/andre/.xinitrc to rotate HDMI-2 (Pi 5 typical) instead of HDMI-1
# 4) Forces SCREEN_RES=1280,400 right before chromium launches
# 5) Restarts localdisplay.service (X + chromium)
# 6) Re-collects state
#
# Usage (from home directory):
#   cd ~/moodeaudio-cursor && ./tools/fix/pi-display-fix-now.sh 192.168.10.2 andre
#
# Notes:
# - You will be prompted for SSH password, and possibly sudo password on the Pi.
# - This is intended as a "one-hour debug permission" helper; revert by restoring
#   the created .xinitrc backup if needed.
#
################################################################################

set -euo pipefail

PI_IP="${1:-192.168.10.2}"
PI_USER="${2:-andre}"

echo "[PI-DISPLAY] Target: ${PI_USER}@${PI_IP}"
echo "[PI-DISPLAY] Connecting (you may be asked for password)..."

ssh -tt -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_IP}" "PI_USER='${PI_USER}' bash -s" <<'REMOTE'
set -euo pipefail

PI_USER="${PI_USER:-andre}"
HOME_DIR="/home/${PI_USER}"

export DISPLAY=:0
export XAUTHORITY="${HOME_DIR}/.Xauthority"

echo "=== BEFORE ==="
echo "--- hdmi_scn_orient ---"
moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || true
echo "--- xdpyinfo ---"
xdpyinfo 2>/dev/null | egrep "dimensions|resolution" || true
echo "--- xrandr ---"
xrandr --query 2>/dev/null | sed -n "1,60p" || true
echo "--- chromium args ---"
ps aux | egrep "chromium-browser.*window-size" | head -3 || true

echo ""
echo "=== APPLY FIX ==="

# Prompt once for sudo and keep credential timestamp alive
sudo -v

# 1) Set hdmi_scn_orient=portrait (moOde rotates HDMI only in this case)
if command -v sqlite3 >/dev/null 2>&1 && [ -f /var/local/www/db/moode-sqlite3.db ]; then
  echo "[FIX] Set hdmi_scn_orient=portrait via sqlite3"
  if ! sudo sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';"; then
    echo "[WARN] sqlite3 update failed, falling back to moodeutl..."
    sudo moodeutl -i "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';" || true
  fi
else
  echo "[FIX] Set hdmi_scn_orient=portrait via moodeutl"
  sudo moodeutl -i "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';" || true
fi

# 2) Replace .xinitrc with a robust Waveshare landscape template (backup first)
TS="$(date +%Y%m%d_%H%M%S)"
sudo cp "${HOME_DIR}/.xinitrc" "${HOME_DIR}/.xinitrc.bak.${TS}" 2>/dev/null || true
echo "[FIX] Backup created: ${HOME_DIR}/.xinitrc.bak.${TS}"

TMP_XINIT="$(mktemp)"
cat > "${TMP_XINIT}" <<XINIT
#!/bin/bash
#
# Ghettoblaster: robust Waveshare 7.9\" HDMI display bootstrap
# Goal: panel is native portrait (400x1280) but we want landscape UI (1280x400)
#

# Screen blanking: Use both Screen saver and DPMS
xset s 600 0
xset +dpms
xset dpms 600 0 0

export DISPLAY=:0
export XAUTHORITY=${HOME_DIR}/.Xauthority

# Get configuration
HDMI_SCN_ORIENT=\$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo landscape)
DSI_SCN_TYPE=\$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'" 2>/dev/null || echo none)
WEBUI_SHOW=\$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'" 2>/dev/null || echo 1)
PEPPY_SHOW=\$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'" 2>/dev/null || echo 0)
PEPPY_TYPE=\$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display_type'" 2>/dev/null || echo meter)

# Force Chromium expectations for Waveshare landscape
SCREEN_RES="1280,400"

# Wait for X / xrandr to be ready
for i in {1..40}; do
  xrandr --query >/dev/null 2>&1 && break
  sleep 0.25
done

# Determine connected HDMI output (Pi5: usually HDMI-2)
HDMI_OUT="\$(xrandr --query 2>/dev/null | awk '/^HDMI-[0-9]+ connected/ {print \$1; exit}')"
[ -z "\$HDMI_OUT" ] && HDMI_OUT="HDMI-2"

# Apply rotation only for HDMI screens and when moOde says "portrait"
if [ "\$DSI_SCN_TYPE" = "none" ] && [ "\$HDMI_SCN_ORIENT" = "portrait" ]; then
  # Reset -> set native mode -> rotate (more reliable than rotate-only)
  DISPLAY=:0 xrandr --output "\$HDMI_OUT" --rotate normal 2>/dev/null || true
  sleep 1
  DISPLAY=:0 xrandr --output "\$HDMI_OUT" --mode 400x1280 2>/dev/null || true
  sleep 1
  DISPLAY=:0 xrandr --output "\$HDMI_OUT" --rotate left 2>/dev/null || true
  sleep 1
fi

# Launch WebUI or Peppy
if [ "\$WEBUI_SHOW" = "1" ]; then
  \$(/var/www/util/sysutil.sh clearbrcache)
  chromium \\
  --app="http://localhost/" \\
  --window-size="\$SCREEN_RES" \\
  --window-position="0,0" \\
  --enable-features="OverlayScrollbar" \\
  --no-first-run \\
  --disable-infobars \\
  --disable-session-crashed-bubble \\
  --kiosk
elif [ "\$PEPPY_SHOW" = "1" ]; then
  if [ "\$PEPPY_TYPE" = "meter" ]; then
    cd /opt/peppymeter && python3 peppymeter.py
  else
    cd /opt/peppyspectrum && python3 spectrum.py
  fi
  chromium \\
  --app="http://localhost/" \\
  --window-size="\$SCREEN_RES" \\
  --window-position="0,0" \\
  --enable-features="OverlayScrollbar" \\
  --no-first-run \\
  --disable-infobars \\
  --disable-session-crashed-bubble \\
  --kiosk
fi
XINIT

sudo install -m 0755 -o "${PI_USER}" -g "${PI_USER}" "${TMP_XINIT}" "${HOME_DIR}/.xinitrc"
rm -f "${TMP_XINIT}"

echo "[FIX] Restarting localdisplay.service..."
sudo systemctl restart localdisplay.service
sleep 2

echo ""
echo "=== AFTER ==="
echo "--- hdmi_scn_orient ---"
moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || true
echo "--- xdpyinfo ---"
xdpyinfo 2>/dev/null | egrep "dimensions|resolution" || true
echo "--- xrandr ---"
xrandr --query 2>/dev/null | sed -n "1,60p" || true
echo "--- chromium args ---"
ps aux | egrep "chromium-browser.*window-size" | head -3 || true

echo ""
echo "[PI-DISPLAY] Done."
REMOTE

