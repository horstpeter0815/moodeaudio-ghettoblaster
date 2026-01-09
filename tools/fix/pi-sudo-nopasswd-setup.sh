#!/bin/bash
################################################################################
#
# Pi sudo NOPASSWD bootstrap (Mac -> Pi)
#
# Goal:
# - Remove "pseudo permissions" friction during development
# - Keep it reasonably safe by default (limited command allowlist)
#
# Usage (from home dir):
#   cd ~/moodeaudio-cursor && ./tools/fix/pi-sudo-nopasswd-setup.sh 192.168.10.2 andre
#
# To allow EVERYTHING (not recommended):
#   cd ~/moodeaudio-cursor && ./tools/fix/pi-sudo-nopasswd-setup.sh 192.168.10.2 andre --all
#
################################################################################

set -euo pipefail

PI_IP="${1:-192.168.10.2}"
PI_USER="${2:-andre}"
MODE="${3:-}"

SUDOERS_FILE="/etc/sudoers.d/90-${PI_USER}-moode-nopasswd"

echo "[SUDO-NOPASSWD] Target: ${PI_USER}@${PI_IP}"

if [ "${MODE:-}" = "--all" ]; then
  echo "[SUDO-NOPASSWD] WARNING: enabling NOPASSWD:ALL for ${PI_USER}"
  RULES="${PI_USER} ALL=(ALL) NOPASSWD:ALL"
else
  echo "[SUDO-NOPASSWD] Enabling LIMITED NOPASSWD rules for ${PI_USER}"
  # Minimal allowlist for our workflows (status/restart, logs, moOde db tool)
  RULES="$(cat <<EOF
${PI_USER} ALL=(root) NOPASSWD: /usr/bin/systemctl status localdisplay.service, /usr/bin/systemctl restart localdisplay.service, /usr/bin/systemctl restart localdisplay, /usr/bin/systemctl status nginx.service, /usr/bin/systemctl restart nginx.service, /usr/bin/systemctl status php8.4-fpm.service, /usr/bin/systemctl restart php8.4-fpm.service, /usr/bin/systemctl status mpd.service, /usr/bin/systemctl restart mpd.service, /usr/bin/systemctl reboot
${PI_USER} ALL=(root) NOPASSWD: /usr/bin/journalctl, /usr/bin/journalctl -u localdisplay.service, /usr/bin/journalctl -u mpd.service, /usr/bin/journalctl -u nginx.service, /usr/bin/journalctl -u php8.4-fpm.service
${PI_USER} ALL=(root) NOPASSWD: /usr/local/bin/moodeutl *
EOF
)"
fi

echo "[SUDO-NOPASSWD] Installing sudoers drop-in: ${SUDOERS_FILE}"
echo "[SUDO-NOPASSWD] (you may be prompted ONCE for password)"

RULES_B64="$(printf '%s' "$RULES" | base64 | tr -d '\n')"

ssh -tt -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_IP}" "PI_USER='${PI_USER}' SUDOERS_FILE='${SUDOERS_FILE}' RULES_B64='${RULES_B64}' bash -s" <<'REMOTE'
set -euo pipefail

# Ensure sudo works (prompts once)
sudo -v

tmp="$(mktemp)"
{
  echo "# Managed by moodeaudio-cursor: tools/fix/pi-sudo-nopasswd-setup.sh"
  echo "Defaults:${PI_USER} !requiretty"
  printf '%s' "${RULES_B64}" | base64 -d
  echo ""
} > "$tmp"

sudo install -m 0440 "$tmp" "$SUDOERS_FILE"
rm -f "$tmp"

if command -v visudo >/dev/null 2>&1; then
  sudo visudo -cf "$SUDOERS_FILE"
  echo "[SUDO-NOPASSWD] OK: visudo validation passed"
else
  echo "[SUDO-NOPASSWD] WARN: visudo not found; installed without validation"
fi
REMOTE

echo "[SUDO-NOPASSWD] Done."

