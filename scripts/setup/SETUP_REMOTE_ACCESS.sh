#!/bin/bash
################################################################################
#
# Setup Remote Access for Additional User
#
# Configures:
# - SSH access for new user
# - Password or key-based authentication
# - Sudo access if needed
# - Web UI access (moOde)
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

log "=== Remote Access Setup ==="
echo ""

# Get user details
read -p "Enter username for remote access: " REMOTE_USER
if [ -z "$REMOTE_USER" ]; then
    error "Username required"
    exit 1
fi

read -p "Create new user or use existing? (new/existing): " USER_TYPE

if [ "$USER_TYPE" = "new" ]; then
    # Create new user
    if id "$REMOTE_USER" >/dev/null 2>&1; then
        warn "User $REMOTE_USER already exists, using existing user"
    else
        log "Creating new user: $REMOTE_USER"
        sudo useradd -m -s /bin/bash "$REMOTE_USER" || {
            error "Failed to create user"
            exit 1
        }
        log "✅ User created"
        
        # Set password
        echo ""
        info "Setting password for $REMOTE_USER"
        sudo passwd "$REMOTE_USER"
    fi
else
    # Use existing user
    if ! id "$REMOTE_USER" >/dev/null 2>&1; then
        error "User $REMOTE_USER does not exist"
        exit 1
    fi
    log "Using existing user: $REMOTE_USER"
fi

# Add to sudoers (optional)
read -p "Grant sudo access? (y/n): " GRANT_SUDO
if [[ "$GRANT_SUDO" =~ ^[Yy] ]]; then
    log "Granting sudo access..."
    echo "$REMOTE_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$REMOTE_USER" > /dev/null
    sudo chmod 0440 "/etc/sudoers.d/$REMOTE_USER"
    log "✅ Sudo access granted"
fi

# SSH key setup (optional)
read -p "Add SSH public key? (y/n): " ADD_KEY
if [[ "$ADD_KEY" =~ ^[Yy] ]]; then
    echo ""
    info "Paste SSH public key (will be added to ~/.ssh/authorized_keys):"
    read -p "SSH key: " SSH_KEY
    
    if [ -n "$SSH_KEY" ]; then
        sudo -u "$REMOTE_USER" mkdir -p "/home/$REMOTE_USER/.ssh"
        echo "$SSH_KEY" | sudo -u "$REMOTE_USER" tee -a "/home/$REMOTE_USER/.ssh/authorized_keys" > /dev/null
        sudo chmod 700 "/home/$REMOTE_USER/.ssh"
        sudo chmod 600 "/home/$REMOTE_USER/.ssh/authorized_keys"
        sudo chown -R "$REMOTE_USER:$REMOTE_USER" "/home/$REMOTE_USER/.ssh"
        log "✅ SSH key added"
    fi
fi

# Ensure SSH is enabled
log "Ensuring SSH is enabled..."
sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null || true
sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null || true
log "✅ SSH service enabled"

# Get Pi IP addresses
log "Getting Pi IP addresses..."
ETH_IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "Not connected")
WIFI_IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "Not connected")

echo ""
log "=== Remote Access Configured ==="
echo ""
info "User: $REMOTE_USER"
if [[ "$GRANT_SUDO" =~ ^[Yy] ]]; then
    echo "  ✅ Sudo access: Granted"
fi
if [[ "$ADD_KEY" =~ ^[Yy] ]]; then
    echo "  ✅ SSH key: Added"
fi
echo ""
info "Pi IP Addresses:"
if [ "$ETH_IP" != "Not connected" ]; then
    echo "  Ethernet: $ETH_IP"
fi
if [ "$WIFI_IP" != "Not connected" ]; then
    echo "  WiFi: $WIFI_IP"
fi
echo ""
info "Remote Access:"
if [ "$ETH_IP" != "Not connected" ]; then
    echo "  SSH: ssh $REMOTE_USER@$ETH_IP"
    echo "  Web UI: http://$ETH_IP/"
fi
if [ "$WIFI_IP" != "Not connected" ] && [ "$WIFI_IP" != "$ETH_IP" ]; then
    echo "  SSH: ssh $REMOTE_USER@$WIFI_IP"
    echo "  Web UI: http://$WIFI_IP/"
fi
echo ""
info "moOde Web UI:"
echo "  Default login: no login required (or check moOde docs)"
echo ""
info "To find Pi IP from Mac:"
echo "  cd ~/moodeaudio-cursor && bash scripts/network/FIND_PI_IP.sh"
