#!/bin/bash
################################################################################
#
# Fix SSH "REMOTE HOST IDENTIFICATION HAS CHANGED!" for a Pi that was reflashed
#
# Typical scenario:
# - Same IP (e.g., 192.168.10.2) but new SD image → new SSH host keys
# - Your Mac refuses to connect due to stale known_hosts entry
#
# What this script does:
# - Removes the old known_hosts entry for the target IP/hostname
# - Reconnects once with StrictHostKeyChecking=accept-new to learn the new key
#
# Usage (from home directory):
#   cd ~/moodeaudio-cursor && ./tools/fix/fix-ssh-hostkey.sh 192.168.10.2 andre
#
################################################################################

set -euo pipefail

IP="${1:-192.168.10.2}"
USER="${2:-andre}"

echo "[SSH] Removing old host key for ${IP} (if present)..."
ssh-keygen -R "${IP}" >/dev/null 2>&1 || true

echo "[SSH] Connecting once to accept new host key..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "${USER}@${IP}" "echo CONNECTED && hostname && uname -a"

echo "[SSH] Done. Future SSH connections to ${USER}@${IP} should work without the host key warning."

