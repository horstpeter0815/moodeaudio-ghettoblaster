#!/bin/bash
################################################################################
#
# Apply SSH and Ethernet Configuration to SD Card
#
# Run this when SD card is mounted in Mac
# Configures SSH and Ethernet directly on SD card
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

# Find SD card volumes
BOOTFS=""
ROOTFS=""

for vol in /Volumes/*; do
    if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ]; then
        if [ -f "$vol/config.txt" ] || [ -f "$vol/cmdline.txt" ]; then
            BOOTFS="$vol"
            log "Found bootfs: $BOOTFS"
        fi
        if [ -d "$vol/etc" ] && [ -d "$vol/usr" ]; then
            ROOTFS="$vol"
            log "Found rootfs: $ROOTFS"
        fi
    fi
done

if [ -z "$BOOTFS" ] || [ -z "$ROOTFS" ]; then
    error "SD card not found!"
    error "Please insert SD card and ensure it's mounted"
    exit 1
fi

log "=== Applying SSH and Ethernet Configuration to SD Card ==="

# Step 1: Enable SSH
log "Step 1: Enabling SSH..."
touch "$BOOTFS/ssh" 2>/dev/null || {
    error "Cannot create SSH file - may need sudo"
    exit 1
}
log "✅ SSH file created: $BOOTFS/ssh"

# Step 2: Configure Ethernet
log "Step 2: Configuring Ethernet..."
ETHERNET_CONF="$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"

# Create directory if needed
mkdir -p "$(dirname "$ETHERNET_CONF")" 2>/dev/null || {
    error "Cannot create directory - may need sudo"
    exit 1
}

# Backup if exists
if [ -f "$ETHERNET_CONF" ]; then
    cp "$ETHERNET_CONF" "${ETHERNET_CONF}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
fi

# Create Ethernet config
cat > "$ETHERNET_CONF" << 'EOF'
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

log "✅ Ethernet configured: $ETHERNET_CONF"

echo ""
log "=== Configuration Applied ==="
echo ""
info "SSH:"
echo "  - File created: $BOOTFS/ssh"
echo ""
info "Ethernet:"
echo "  - Static IP: 192.168.10.2/24"
echo "  - Gateway: 192.168.10.1"
echo "  - Config: $ETHERNET_CONF"
echo ""
info "Next steps:"
echo "  1. Eject SD card safely"
echo "  2. Insert into Pi"
echo "  3. Boot Pi"
echo "  4. Connect via: ssh andre@192.168.10.2"
