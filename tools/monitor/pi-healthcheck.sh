#!/bin/bash
################################################################################
#
# Pi healthcheck (Mac -> Pi)
#
# Purpose:
# - Turn "connection problems" into deterministic, copy/paste diagnostics
# - Verify: SSH reachability, HTTP reachability, display stack status
#
# Usage (from home dir):
#   cd ~/moodeaudio-cursor && ./tools/monitor/pi-healthcheck.sh 192.168.10.2 andre
#
################################################################################

set -euo pipefail

PI_IP="${1:-192.168.10.2}"
PI_USER="${2:-andre}"

echo "[PI-HEALTH] Target: ${PI_USER}@${PI_IP}"
echo ""

echo "=== Network ==="
if nc -vz -G 1 -w 2 "$PI_IP" 22 >/dev/null 2>&1; then
  echo "SSH (22): ✅ open"
else
  echo "SSH (22): ❌ closed"
fi

if curl -fsS -I --max-time 3 "http://${PI_IP}/" >/dev/null 2>&1; then
  echo "HTTP (80): ✅ responding"
else
  echo "HTTP (80): ❌ not responding"
fi

echo ""
echo "=== SSH auth (key-based) ==="
if ssh -o BatchMode=yes -o ConnectTimeout=3 "${PI_USER}@${PI_IP}" 'echo ok' >/dev/null 2>&1; then
  echo "SSH key auth: ✅ ok"
else
  echo "SSH key auth: ❌ failed (run ./tools/fix/pi-ssh-key-setup.sh)"
fi

echo ""
echo "=== Runtime snapshot ==="
ssh -o ConnectTimeout=5 "${PI_USER}@${PI_IP}" 'bash -lc '"'"'
set -e
echo "host=$(hostname)"
echo "time=$(date -Is)"
echo "uptime=$(uptime -p 2>/dev/null || uptime)"
echo "--- systemd ---"
systemctl is-system-running 2>/dev/null || true
echo "--- localdisplay ---"
systemctl is-active localdisplay.service 2>/dev/null || true
systemctl status --no-pager --full localdisplay.service 2>/dev/null | tail -40 || true
echo "--- X11 ---"
export DISPLAY=:0
xdpyinfo 2>/dev/null | egrep "dimensions|resolution" || true
echo "--- xrandr ---"
xrandr --query 2>/dev/null | sed -n "1,40p" || true
echo "--- WebUI localhost ---"
curl -sS -I http://localhost/ 2>/dev/null | head -10 || true
'"'"'' || true

echo ""
echo "[PI-HEALTH] Done."

