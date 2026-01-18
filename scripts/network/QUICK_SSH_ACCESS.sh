#!/bin/bash
################################################################################
#
# Quick SSH Access Setup
#
# Ensures SSH is enabled and network is configured
# Run this when SD card is in Mac
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() { echo -e "\033[0;32m[SSH]${NC} $1"; }
error() { echo -e "\033[0;31m[ERROR]${NC} $1" >&2; }

# Find SD card
BOOTFS=""
for vol in /Volumes/*; do
    if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ]; then
        if [ -f "$vol/config.txt" ] || [ -f "$vol/cmdline.txt" ]; then
            BOOTFS="$vol"
            break
        fi
    fi
done

if [ -z "$BOOTFS" ]; then
    error "SD card boot partition not found!"
    error "Insert SD card and ensure it's mounted"
    exit 1
fi

log "Found boot partition: $BOOTFS"

# Enable SSH
log "Enabling SSH..."
touch "$BOOTFS/ssh" 2>/dev/null && log "✅ SSH enabled" || error "Failed to enable SSH"

# Find rootfs for network config
ROOTFS=""
for vol in /Volumes/*; do
    if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ] && [ "$vol" != "$BOOTFS" ]; then
        if [ -d "$vol/etc" ] && [ -d "$vol/usr" ]; then
            ROOTFS="$vol"
            break
        fi
    fi
done

if [ -n "$ROOTFS" ]; then
    log "Found root partition: $ROOTFS"
    
    # Ensure Ethernet is configured
    ETHERNET_CONF="$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"
    if [ ! -f "$ETHERNET_CONF" ]; then
        log "Configuring Ethernet (192.168.10.2)..."
        mkdir -p "$(dirname "$ETHERNET_CONF")" 2>/dev/null || true
        
        cat > "$ETHERNET_CONF" << 'EOF'
[connection]
id=Ethernet
uuid=f8eba0b7-862d-4ccc-b93a-52815eb9c28d
type=ethernet
interface-name=eth0
autoconnect=true

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=192.168.10.1;8.8.8.8

[ipv6]
method=auto
EOF
        log "✅ Ethernet configured: 192.168.10.2"
    else
        log "✅ Ethernet already configured"
    fi
fi

echo ""
log "=== SSH Access Ready ==="
echo ""
echo "After boot, connect via:"
echo "  ssh andre@192.168.10.2"
echo ""
echo "Password: 0815"
echo ""
