#!/bin/bash
################################################################################
#
# Run on Mac - Executes ADD_SSH_KEY_TO_USER.sh on Pi via SSH
#
# Usage: RUN_ON_PI_ADD_SSH_KEY.sh <username> "<ssh-public-key>"
#
################################################################################

set -euo pipefail

USERNAME="${1:-}"
SSH_KEY="${2:-}"
PI_HOST="${PI_HOST:-192.168.10.2}"
PI_USER="${PI_USER:-andre}"

if [ -z "$USERNAME" ] || [ -z "$SSH_KEY" ]; then
    echo "Usage: $0 <username> \"<ssh-public-key>\""
    echo "Example: $0 andre \"ssh-rsa AAAAB3...\""
    exit 1
fi

log() { echo -e "\033[0;32m[RUN]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

log "Connecting to Pi and adding SSH key..."

# First, ensure script exists on Pi
log "Checking if script exists on Pi..."
ssh "$PI_USER@$PI_HOST" "test -f ~/moodeaudio-cursor/scripts/setup/ADD_SSH_KEY_TO_USER.sh" 2>/dev/null || {
    error "Script not found on Pi. Syncing repo first..."
    echo ""
    echo "Run this first:"
    echo "  cd ~/moodeaudio-cursor && ./tools/dev.sh --sync-pi"
    exit 1
}

# Run the script on Pi
log "Running script on Pi..."
ssh "$PI_USER@$PI_HOST" "cd ~/moodeaudio-cursor && sudo bash scripts/setup/ADD_SSH_KEY_TO_USER.sh '$USERNAME' '$SSH_KEY'"
