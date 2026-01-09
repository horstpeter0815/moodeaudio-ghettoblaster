#!/bin/bash
################################################################################
#
# Disable Pi "dev mode" (Mac -> Pi)
#
# Removes:
# - sudo NOPASSWD drop-in installed by pi-sudo-nopasswd-setup.sh
# Optionally removes:
# - the Mac's public key from ~/.ssh/authorized_keys on the Pi
#
# Usage:
#   cd ~/moodeaudio-cursor && ./tools/fix/pi-dev-mode-disable.sh 192.168.10.2 andre
#
################################################################################

set -euo pipefail

PI_IP="${1:-192.168.10.2}"
PI_USER="${2:-andre}"
MODE="${3:-}"

SUDOERS_FILE="/etc/sudoers.d/90-${PI_USER}-moode-nopasswd"

KEY_FILE="$HOME/.ssh/id_ed25519.pub"

echo "[DEV-MODE] Disabling dev mode for ${PI_USER}@${PI_IP}"
echo ""

echo "[DEV-MODE] Removing sudoers drop-in: ${SUDOERS_FILE}"
ssh -tt -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_IP}" "bash -s" <<REMOTE
set -euo pipefail
sudo -v
if [ -f "${SUDOERS_FILE}" ]; then
  sudo rm -f "${SUDOERS_FILE}"
  echo "[DEV-MODE] sudoers drop-in removed"
else
  echo "[DEV-MODE] sudoers drop-in not present"
fi
REMOTE

if [ -f "$KEY_FILE" ]; then
  PUB_KEY_B64="$(base64 < "$KEY_FILE" | tr -d '\n')"
  if [ "${MODE:-}" = "--remove-key" ]; then
    echo ""
    echo "[DEV-MODE] Removing THIS Mac's SSH key from Pi authorized_keys..."
    ssh -tt -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_IP}" "PUB_KEY_B64='${PUB_KEY_B64}' bash -s" <<'REMOTE2'
set -euo pipefail
PUB_KEY="$(printf '%s' "${PUB_KEY_B64}" | base64 -d)"
if [ -f "$HOME/.ssh/authorized_keys" ]; then
  tmp="$(mktemp)"
  grep -vxF "$PUB_KEY" "$HOME/.ssh/authorized_keys" > "$tmp" || true
  mv "$tmp" "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
  echo "[DEV-MODE] SSH key removed from authorized_keys"
else
  echo "[DEV-MODE] No authorized_keys found"
fi
REMOTE2
  else
    echo ""
    echo "[DEV-MODE] Keeping SSH key auth enabled (pass --remove-key to remove it)"
  fi
else
  echo ""
  echo "[DEV-MODE] No local public key found at ${KEY_FILE}; skipping authorized_keys cleanup"
fi

echo ""
echo "[DEV-MODE] Done."

