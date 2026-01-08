#!/bin/bash
################################################################################
#
# APPLY UNIFIED NETWORK MANAGER TO SD CARD
#
# This script applies the unified network manager configuration to a mounted
# SD card, disabling conflicting services and enabling the new mode-based system.
#
################################################################################

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root (use sudo)"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[APPLY]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  APPLYING UNIFIED NETWORK MANAGER                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    error "Root partition not found. Please mount SD card."
    exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log "Using rootfs: $ROOTFS"
log "Project root: $PROJECT_ROOT"
echo ""

################################################################################
# 1. COPY NETWORK MODE MANAGER SCRIPT
################################################################################

log "1. Copying network mode manager script..."
SRC_SCRIPT="$PROJECT_ROOT/moode-source/usr/local/bin/network-mode-manager.sh"
DST_SCRIPT="$ROOTFS/usr/local/bin/network-mode-manager.sh"

if [ ! -f "$SRC_SCRIPT" ]; then
    error "Source script not found: $SRC_SCRIPT"
    exit 1
fi

mkdir -p "$ROOTFS/usr/local/bin"
cp "$SRC_SCRIPT" "$DST_SCRIPT"
chmod +x "$DST_SCRIPT"
log "✅ Script copied and made executable"

################################################################################
# 2. COPY SERVICE FILES
################################################################################

log "2. Copying network mode service files..."
SERVICES_DIR="$ROOTFS/lib/systemd/system"
mkdir -p "$SERVICES_DIR"

for service in \
    "network-mode-manager.service" \
    "network-mode-usb-gadget.service" \
    "network-mode-ethernet-static.service" \
    "network-mode-ethernet-dhcp.service" \
    "network-mode-wifi.service"; do
    
    SRC_SERVICE="$PROJECT_ROOT/moode-source/lib/systemd/system/$service"
    DST_SERVICE="$SERVICES_DIR/$service"
    
    if [ -f "$SRC_SERVICE" ]; then
        cp "$SRC_SERVICE" "$DST_SERVICE"
        chmod 644 "$DST_SERVICE"
        log "✅ Copied: $service"
    else
        warn "Service file not found: $SRC_SERVICE"
    fi
done

################################################################################
# 3. DISABLE CONFLICTING SERVICES
################################################################################

log "3. Disabling conflicting network services..."
WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANTS_DIR"

# Disable old services that conflict with unified network manager
CONFLICTING_SERVICES=(
    "00-boot-network-ssh.service"
    "02-eth0-configure.service"
    "03-network-configure.service"
    "04-network-lan.service"
)

for service in "${CONFLICTING_SERVICES[@]}"; do
    if [ -L "$WANTS_DIR/$service" ]; then
        rm -f "$WANTS_DIR/$service"
        log "✅ Disabled: $service"
    elif [ -f "$WANTS_DIR/$service" ]; then
        rm -f "$WANTS_DIR/$service"
        log "✅ Removed: $service"
    fi
done

################################################################################
# 4. ENABLE UNIFIED NETWORK MANAGER
################################################################################

log "4. Enabling unified network manager service..."
ln -sf "/lib/systemd/system/network-mode-manager.service" \
       "$WANTS_DIR/network-mode-manager.service"
log "✅ Network mode manager enabled"

################################################################################
# 5. CONFIGURE NETWORKMANAGER (Ethernet DHCP priority)
################################################################################

log "5. Configuring NetworkManager..."
NM_CONN_DIR="$ROOTFS/etc/NetworkManager/system-connections"
mkdir -p "$NM_CONN_DIR"

# Create/update Ethernet connection with DHCP and highest priority
cat > "$NM_CONN_DIR/Ethernet.nmconnection" << 'EOF'
[connection]
id=Ethernet
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=200

[ethernet]

[ipv4]
method=auto
dns=8.8.8.8;8.8.4.4

[ipv6]
method=auto
EOF

chmod 600 "$NM_CONN_DIR/Ethernet.nmconnection"
log "✅ NetworkManager Ethernet connection configured (DHCP, priority 200)"

# Disable WiFi connections (lower priority)
find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "type=wifi\|802-11-wireless" {} \; 2>/dev/null | while read file; do
    # Set autoconnect=false and priority=0
    if grep -q "autoconnect=true" "$file"; then
        sed -i.bak 's/autoconnect=true/autoconnect=false/' "$file" 2>/dev/null || true
    fi
    if grep -q "autoconnect-priority=" "$file"; then
        sed -i.bak 's/autoconnect-priority=[0-9]*/autoconnect-priority=0/' "$file" 2>/dev/null || true
    else
        echo "autoconnect=false" >> "$file"
        echo "autoconnect-priority=0" >> "$file"
    fi
    warn "Disabled WiFi connection: $(basename "$file")"
done

################################################################################
# 6. CREATE MODE SELECTION FILE (for Ethernet DHCP mode)
################################################################################

log "6. Creating mode selection file..."
# Create a file that can be edited on boot partition to select mode
cat > "$ROOTFS/boot/firmware/network-mode.info" << 'EOF'
# Network Mode Selection
#
# To use Ethernet DHCP mode (for Mac Internet Sharing), create this file:
#   /boot/firmware/network-mode
#   with content: ethernet-dhcp
#
# To use Ethernet Static mode (default), delete or don't create the file.
# To use USB Gadget mode, connect USB cable (auto-detected).
#
EOF

log "✅ Mode selection info file created"

################################################################################
# 7. DISABLE WIFI SERVICES
################################################################################

log "7. Disabling WiFi services..."
# Disable wpa_supplicant to prevent WiFi from connecting before Ethernet
rm -f "$WANTS_DIR/wpa_supplicant.service" 2>/dev/null || true
rm -f "$WANTS_DIR/wpa_supplicant@wlan0.service" 2>/dev/null || true
log "✅ WiFi services disabled (can be re-enabled if needed)"

################################################################################
# SUMMARY
################################################################################

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ UNIFIED NETWORK MANAGER APPLIED                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "Summary:"
echo "  ✅ Network mode manager script installed"
echo "  ✅ Network mode services installed"
echo "  ✅ Conflicting services disabled"
echo "  ✅ NetworkManager configured (Ethernet DHCP priority 200)"
echo "  ✅ WiFi connections disabled"
echo "  ✅ WiFi services disabled"
echo ""
echo "Network modes available:"
echo "  1. USB Gadget (auto-detected when usb0 interface exists)"
echo "  2. Ethernet Static (default for direct Mac connection)"
echo "  3. Ethernet DHCP (create /boot/firmware/network-mode with 'ethernet-dhcp')"
echo "  4. WiFi (auto-detected if Ethernet not available)"
echo ""
warn "To enable Ethernet DHCP mode:"
echo "  Create file: /boot/firmware/network-mode"
echo "  Content: ethernet-dhcp"
echo ""
log "Next steps:"
echo "  1. Eject SD card"
echo "  2. Boot Pi"
echo "  3. Network mode manager will auto-detect and configure network"
echo ""



