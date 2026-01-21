#!/bin/bash
################################################################################
#
# Pi SSH key bootstrap (Mac -> Pi)
#
# Goal: eliminate repeated password prompts and make Pi reachable/debuggable
# deterministically after reboots/power cuts.
#
# Usage (from home dir):
#   cd ~/moodeaudio-cursor && ./tools/fix/pi-ssh-key-setup.sh 192.168.10.2 andre
#
# Notes:
# - Prompts once for the Pi password (e.g., 0815) to install the public key.
# - Does NOT print or store any passwords.
#
################################################################################

set -euo pipefail

PI_IP="${1:-192.168.10.2}"
PI_USER="${2:-andre}"

KEY_FILE="$HOME/.ssh/id_ed25519"
PUB_FILE="$HOME/.ssh/id_ed25519.pub"

echo "[SSH-KEY] Target: ${PI_USER}@${PI_IP}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$KEY_FILE" ] || [ ! -f "$PUB_FILE" ]; then
  echo "[SSH-KEY] No local ed25519 key found, generating: $KEY_FILE"
  ssh-keygen -t ed25519 -N "" -f "$KEY_FILE" >/dev/null
fi

PUB_KEY_B64="$(base64 < "$PUB_FILE" | tr -d '\n')"

echo "[SSH-KEY] Installing public key on Pi (you will be prompted for Pi password)..."

# Use a TTY so SSH can prompt for password when needed.
ssh -tt -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_IP}" "PUB_KEY_B64='${PUB_KEY_B64}' bash -s" <<'REMOTE'
set -euo pipefail

umask 077
mkdir -p "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/authorized_keys"

PUB_KEY="$(printf '%s' "${PUB_KEY_B64}" | base64 -d)"

# Avoid duplicates
grep -qxF "$PUB_KEY" "$HOME/.ssh/authorized_keys" || printf '%s\n' "$PUB_KEY" >> "$HOME/.ssh/authorized_keys"

echo "[SSH-KEY] authorized_keys updated"
REMOTE

echo "[SSH-KEY] Verifying key-based SSH (no password prompt expected)..."
ssh -o BatchMode=yes -o ConnectTimeout=5 "${PI_USER}@${PI_IP}" 'echo "[SSH-KEY] OK: key auth works"'

echo "[SSH-KEY] Done."

