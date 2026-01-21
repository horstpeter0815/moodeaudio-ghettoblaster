#!/bin/bash
################################################################################
#
# Setup SSH and Ethernet for Remote Access
#
# Configures:
# - SSH enabled on boot
# - Ethernet static IP: 192.168.10.2/24
# - SSH service enabled
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

log "=== Setting up SSH and Ethernet ==="

# Step 1: Enable SSH on boot
log "Step 1: Enabling SSH on boot..."
if [ -d "/boot/firmware" ]; then
    touch /boot/firmware/ssh 2>/dev/null || sudo touch /boot/firmware/ssh
    log "✅ SSH file created in /boot/firmware/ssh"
elif [ -d "/boot" ]; then
    touch /boot/ssh 2>/dev/null || sudo touch /boot/ssh
    log "✅ SSH file created in /boot/ssh"
else
    warn "Boot directory not found - SSH may need manual setup"
fi

# Step 2: Enable SSH service
log "Step 2: Enabling SSH service..."
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null || true
    sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null || true
    log "✅ SSH service enabled and started"
else
    warn "systemctl not available - SSH service may need manual setup"
fi

# Step 3: Configure Ethernet static IP
log "Step 3: Configuring Ethernet static IP..."
ETHERNET_CONF="/etc/NetworkManager/system-connections/Ethernet.nmconnection"

if [ -f "$ETHERNET_CONF" ]; then
    # Backup existing config
    sudo cp "$ETHERNET_CONF" "${ETHERNET_CONF}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Create new config with static IP
    sudo tee "$ETHERNET_CONF" > /dev/null << 'EOF'
#########################################
# This file is managed by moOde          
# Ethernet - Static IP for SSH          
#########################################

[connection]
id=Ethernet
uuid=f8eba0b7-862d-4ccc-b93a-52815eb9c28d
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=192.168.10.1;8.8.8.8

[ipv6]
addr-gen-mode=default
method=auto
EOF
    
    # Set correct permissions
    sudo chmod 600 "$ETHERNET_CONF"
    sudo chown root:root "$ETHERNET_CONF"
    
    log "✅ Ethernet configured with static IP 192.168.10.2/24"
    
    # Reload NetworkManager
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl reload NetworkManager 2>/dev/null || true
        log "✅ NetworkManager reloaded"
    fi
else
    warn "Ethernet config not found at $ETHERNET_CONF"
    info "Creating new Ethernet configuration..."
    
    sudo mkdir -p /etc/NetworkManager/system-connections/
    sudo tee "$ETHERNET_CONF" > /dev/null << 'EOF'
#########################################
# This file is managed by moOde          
# Ethernet - Static IP for SSH          
#########################################

[connection]
id=Ethernet
uuid=f8eba0b7-862d-4ccc-b93a-52815eb9c28d
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=192.168.10.1;8.8.8.8

[ipv6]
addr-gen-mode=default
method=auto
EOF
    
    sudo chmod 600 "$ETHERNET_CONF"
    sudo chown root:root "$ETHERNET_CONF"
    log "✅ Ethernet configuration created"
fi

# Step 4: Verify SSH configuration
log "Step 4: Verifying SSH configuration..."
if [ -f /etc/ssh/sshd_config ]; then
    # Ensure password authentication is enabled (if not already configured)
    if ! grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
        echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        log "✅ Password authentication enabled"
    fi
    
    # Ensure root login is configured (usually PermitRootLogin yes or without-password)
    if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
        echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        log "✅ Root login enabled"
    fi
fi

# Step 5: Restart services
log "Step 5: Restarting services..."
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null || true
    sudo systemctl restart NetworkManager 2>/dev/null || true
    log "✅ Services restarted"
fi

echo ""
log "=== Setup Complete ==="
echo ""
info "SSH Configuration:"
echo "  - SSH enabled on boot"
echo "  - SSH service running"
echo ""
info "Network Configuration:"
echo "  - Ethernet: Static IP 192.168.10.2/24"
echo "  - Gateway: 192.168.10.1"
echo "  - DNS: 192.168.10.1, 8.8.8.8"
echo ""
info "After network connects, SSH will be available at:"
echo "  ssh andre@192.168.10.2"
echo ""
info "To test connection:"
echo "  ping 192.168.10.2"
echo "  ssh andre@192.168.10.2"
