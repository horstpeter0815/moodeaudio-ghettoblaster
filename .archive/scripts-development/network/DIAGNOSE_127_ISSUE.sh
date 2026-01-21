#!/bin/bash
################################################################################
#
# DIAGNOSE 127.0.1.1 NETWORK ISSUE
#
# The Pi is showing 127.0.1.1 which means network interfaces are not configured.
# This script diagnoses the issue and provides fixes.
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[DIAG]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DIAGNOSING 127.0.1.1 NETWORK ISSUE                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    error "Root partition not found. Is SD card mounted?"
    exit 1
fi

log "Using rootfs: $ROOTFS"
echo ""

################################################################################
# CHECK 1: Network Interfaces
################################################################################

section "1. Checking network interface configuration..."

if [ -f "$ROOTFS/etc/network/interfaces" ]; then
    echo "Found /etc/network/interfaces:"
    cat "$ROOTFS/etc/network/interfaces" | grep -E "^[^#]|^#" | head -20
    echo ""
fi

################################################################################
# CHECK 2: NetworkManager Configuration
################################################################################

section "2. Checking NetworkManager connections..."

NM_DIR="$ROOTFS/etc/NetworkManager/system-connections"
if [ -d "$NM_DIR" ]; then
    echo "NetworkManager connections found:"
    ls -la "$NM_DIR"/*.nmconnection 2>/dev/null | awk '{print $9}' | xargs -n1 basename || echo "None"
    echo ""
else
    warn "NetworkManager connections directory not found"
    echo ""
fi

################################################################################
# CHECK 3: Systemd Network Services
################################################################################

section "3. Checking systemd network services..."

WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"

echo "Enabled network services:"
ls -la "$WANTS_DIR"/*network* "$WANTS_DIR"/*eth* "$WANTS_DIR"/*wifi* 2>/dev/null | awk '{print $9, $10, $11}' || echo "None found"
echo ""

################################################################################
# CHECK 4: Network Mode Manager
################################################################################

section "4. Checking unified network manager..."

if [ -f "$ROOTFS/usr/local/bin/network-mode-manager.sh" ]; then
    log "✅ Network mode manager script exists"
    if [ -L "$WANTS_DIR/network-mode-manager.service" ]; then
        log "✅ Network mode manager service is enabled"
    else
        warn "⚠️  Network mode manager service is NOT enabled"
    fi
else
    warn "⚠️  Network mode manager script NOT found"
    error "The unified network manager has not been applied!"
    echo ""
    echo "To fix this, run:"
    echo "  sudo bash scripts/network/APPLY_UNIFIED_NETWORK.sh"
    echo ""
fi

################################################################################
# CHECK 5: Conflicting Services
################################################################################

section "5. Checking for conflicting services..."

CONFLICTING=(
    "00-boot-network-ssh.service"
    "02-eth0-configure.service"
    "03-network-configure.service"
    "04-network-lan.service"
)

CONFLICTS_FOUND=0
for service in "${CONFLICTING[@]}"; do
    if [ -L "$WANTS_DIR/$service" ]; then
        warn "⚠️  Conflicting service enabled: $service"
        CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
    fi
done

if [ $CONFLICTS_FOUND -eq 0 ]; then
    log "✅ No conflicting services enabled"
else
    error "Found $CONFLICTS_FOUND conflicting service(s)"
fi
echo ""

################################################################################
# RECOMMENDATIONS
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  RECOMMENDATIONS                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f "$ROOTFS/usr/local/bin/network-mode-manager.sh" ]; then
    error "CRITICAL: Unified network manager not installed!"
    echo ""
    echo "Apply the unified network manager:"
    echo "  cd ~/moodeaudio-cursor"
    echo "  sudo bash scripts/network/APPLY_UNIFIED_NETWORK.sh"
    echo ""
fi

if [ $CONFLICTS_FOUND -gt 0 ]; then
    warn "Conflicting services need to be disabled"
    echo ""
    echo "Re-run the application script to disable conflicts:"
    echo "  sudo bash scripts/network/APPLY_UNIFIED_NETWORK.sh"
    echo ""
fi

echo "After applying fixes:"
echo "  1. Eject SD card"
echo "  2. Boot Pi"
echo "  3. Wait 30-60 seconds"
echo "  4. Check IP address: ip addr show"
echo ""
echo "For Ethernet DHCP mode (Mac Internet Sharing):"
echo "  echo 'ethernet-dhcp' > /Volumes/bootfs/network-mode"
echo ""



