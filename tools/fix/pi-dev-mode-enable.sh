#!/bin/bash
################################################################################
#
# Enable Pi "dev mode" (Mac -> Pi)
#
# Dev mode = minimal friction:
# - SSH key auth (no ssh password prompts)
# - Limited sudo NOPASSWD for common maintenance commands
#
# Usage (from home dir):
#   cd ~/moodeaudio-cursor && ./tools/fix/pi-dev-mode-enable.sh 192.168.10.2 andre
#
################################################################################

set -euo pipefail

PI_IP="${1:-192.168.10.2}"
PI_USER="${2:-andre}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[DEV-MODE] Enabling dev mode for ${PI_USER}@${PI_IP}"
echo ""

"${SCRIPT_DIR}/pi-ssh-key-setup.sh" "${PI_IP}" "${PI_USER}"
echo ""
"${SCRIPT_DIR}/pi-sudo-nopasswd-setup.sh" "${PI_IP}" "${PI_USER}"

echo ""
echo "[DEV-MODE] Verify (should not prompt for sudo password):"
echo "cd ~/moodeaudio-cursor && ssh ${PI_USER}@${PI_IP} 'sudo systemctl status localdisplay.service | head -5; echo OK'"

