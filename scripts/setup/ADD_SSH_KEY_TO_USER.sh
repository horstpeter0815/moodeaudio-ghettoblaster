#!/bin/bash
################################################################################
#
# Add SSH Key to Existing User
#
# Quick script to add SSH key and grant sudo to existing user
#
################################################################################

set -euo pipefail

USERNAME="${1:-}"
SSH_KEY="${2:-}"

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username> [ssh-public-key]"
    echo "Example: $0 andre \"ssh-rsa AAAAB3...\""
    exit 1
fi

log() { echo -e "\033[0;32m[SETUP]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

# Check user exists
if ! id "$USERNAME" >/dev/null 2>&1; then
    error "User $USERNAME does not exist"
    exit 1
fi

log "Setting up remote access for existing user: $USERNAME"

# Grant sudo
log "Granting sudo access..."
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$USERNAME" > /dev/null
sudo chmod 0440 "/etc/sudoers.d/$USERNAME"
log "✅ Sudo granted"

# Add SSH key if provided
if [ -n "$SSH_KEY" ]; then
    log "Adding SSH key..."
    sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.ssh"
    echo "$SSH_KEY" | sudo -u "$USERNAME" tee -a "/home/$USERNAME/.ssh/authorized_keys" > /dev/null
    sudo chmod 700 "/home/$USERNAME/.ssh"
    sudo chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
    sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"
    log "✅ SSH key added"
else
    log "No SSH key provided - password authentication will be used"
fi

# Get IPs
ETH_IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "")
WIFI_IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "")

echo ""
log "=== Remote Access Ready ==="
echo ""
echo "User: $USERNAME"
echo "Sudo: ✅ Enabled"
if [ -n "$SSH_KEY" ]; then
    echo "SSH Key: ✅ Added"
fi
echo ""
echo "Access:"
[ -n "$ETH_IP" ] && echo "  ssh $USERNAME@$ETH_IP"
[ -n "$WIFI_IP" ] && [ "$WIFI_IP" != "$ETH_IP" ] && echo "  ssh $USERNAME@$WIFI_IP"
echo ""
[ -n "$ETH_IP" ] && echo "Web UI: http://$ETH_IP/"
