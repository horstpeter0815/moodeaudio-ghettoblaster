#!/bin/bash
################################################################################
# Fix Network Mode Manager Timing Issue
# The service might be running too late or NetworkManager is overriding it
################################################################################

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root (use sudo)"
    exit 1
fi

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ Root partition not found"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  FIXING NETWORK MODE MANAGER TIMING                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# 1. Update network-mode-manager.service to run earlier
################################################################################

log "1. Updating network-mode-manager.service to run earlier..."

SERVICE_FILE="$ROOTFS/lib/systemd/system/network-mode-manager.service"

# Update service to run immediately, not after delay
cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Network Mode Manager - Unified Network Configuration
DefaultDependencies=no
After=local-fs.target
Before=network.target
Before=network-pre.target
Before=NetworkManager.service
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
ExecStart=/usr/local/bin/network-mode-manager.sh

# Retry after NetworkManager starts (in case it overrides)
ExecStartPost=/bin/bash -c 'sleep 10 && /usr/local/bin/network-mode-manager.sh'

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target
EOF

chmod 644 "$SERVICE_FILE"
echo "   ✅ Service updated to run earlier and before NetworkManager"

################################################################################
# 2. Update network-mode-manager.sh to be more aggressive
################################################################################

log "2. Updating network-mode-manager.sh to be more persistent..."

SCRIPT_FILE="$ROOTFS/usr/local/bin/network-mode-manager.sh"

# Check if script exists and update the Ethernet static configuration
if [ -f "$SCRIPT_FILE" ]; then
    # Add a more aggressive retry mechanism at the end
    cat >> "$SCRIPT_FILE" << 'EOF'

################################################################################
# RETRY MECHANISM - Ensure IP is set even if something overrides it
################################################################################

# For Ethernet static mode, verify and retry if needed
if [ "$MODE" = "ethernet-static" ]; then
    ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "")
    
    if [ -z "$ETH0_IP" ] || [ "$ETH0_IP" = "127.0.1.1" ] || [ "$ETH0_IP" != "192.168.10.2" ]; then
        log "⚠️  Ethernet IP incorrect ($ETH0_IP) - retrying configuration..."
        
        # Force static IP configuration
        ip link set eth0 up 2>/dev/null || true
        ip addr flush dev eth0 2>/dev/null || true
        ip addr add 192.168.10.2/24 dev eth0 2>/dev/null || true
        ip route del default 2>/dev/null || true
        ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true
        
        # Verify again
        sleep 2
        ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "")
        if [ "$ETH0_IP" = "192.168.10.2" ]; then
            log "✅ Ethernet static IP corrected: $ETH0_IP"
        else
            log "⚠️  Still having issues with Ethernet IP: $ETH0_IP"
        fi
    fi
fi
EOF
    
    chmod +x "$SCRIPT_FILE"
    echo "   ✅ Script updated with retry mechanism"
else
    echo "   ⚠️  Script file not found: $SCRIPT_FILE"
fi

################################################################################
# 3. Create a watchdog service to continuously ensure network is configured
################################################################################

log "3. Creating network watchdog service..."

WATCHDOG_SERVICE="$ROOTFS/lib/systemd/system/network-watchdog.service"

cat > "$WATCHDOG_SERVICE" << 'EOF'
[Unit]
Description=Network Watchdog - Ensure Network Stays Configured
After=network-mode-manager.service
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
# Run every 60 seconds for first 10 minutes
ExecStart=/bin/bash -c '
    for i in {1..10}; do
        sleep 60
        ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk "{print \$2}" | cut -d/ -f1 || echo "")
        if [ -n "$ETH0_IP" ] && [ "$ETH0_IP" != "127.0.1.1" ] && [ "$ETH0_IP" != "192.168.10.2" ]; then
            echo "Network watchdog: eth0 has wrong IP ($ETH0_IP), reconfiguring..."
            /usr/local/bin/network-mode-manager.sh
        fi
    done
'

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$WATCHDOG_SERVICE"

# Enable watchdog
WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANTS_DIR"
ln -sf "/lib/systemd/system/network-watchdog.service" \
       "$WANTS_DIR/network-watchdog.service" 2>/dev/null || true

echo "   ✅ Network watchdog service created and enabled"

################################################################################
# 4. Ensure NetworkManager doesn't override static IP
################################################################################

log "4. Updating NetworkManager to not override static IP..."

NM_CONN_DIR="$ROOTFS/etc/NetworkManager/system-connections"

# Create Ethernet connection that doesn't interfere
cat > "$NM_CONN_DIR/Ethernet.nmconnection" << 'EOF'
[connection]
id=Ethernet
type=ethernet
interface-name=eth0
autoconnect=false
autoconnect-priority=0

[ethernet]

[ipv4]
method=auto

[ipv6]
method=auto
EOF

chmod 600 "$NM_CONN_DIR/Ethernet.nmconnection"
echo "   ✅ NetworkManager configured to not auto-connect (manual mode takes priority)"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FIXES APPLIED                                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Changes made:"
echo "  ✅ Network mode manager runs BEFORE NetworkManager"
echo "  ✅ Added retry mechanism in script"
echo "  ✅ Created network watchdog service (monitors for 10 minutes)"
echo "  ✅ NetworkManager auto-connect disabled (manual mode priority)"
echo ""
echo "Next steps:"
echo "  1. Eject SD card"
echo "  2. Boot Pi"
echo "  3. Wait 60 seconds"
echo "  4. Check IP: ip addr show eth0"
echo "  5. Should show: 192.168.10.2/24"
echo ""



