#!/bin/bash
################################################################################
# VERIFY NETWORK CONFIGURATION
# Checks that all network fixes have been applied correctly
################################################################################

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ Root partition not found"
    exit 1
fi

NM_CONN_DIR="$ROOTFS/etc/NetworkManager/system-connections"
WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 VERIFYING NETWORK CONFIGURATION                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0

# Check 1: Static IP services disabled
echo "1. Checking static IP services..."
if [ -L "$WANTS_DIR/02-eth0-configure.service" ] || [ -L "$WANTS_DIR/04-network-lan.service" ]; then
    echo "   ❌ Static IP services still enabled"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ Static IP services disabled"
fi

# Check 2: DHCP service enabled
echo ""
echo "2. Checking DHCP service..."
if [ -L "$WANTS_DIR/eth0-dhcp.service" ]; then
    echo "   ✅ DHCP service enabled"
else
    echo "   ❌ DHCP service NOT enabled"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: WiFi services disabled
echo ""
echo "3. Checking WiFi services..."
if [ -L "$WANTS_DIR/wpa_supplicant.service" ] || [ -L "$WANTS_DIR/wpa_supplicant@wlan0.service" ]; then
    echo "   ❌ WiFi services still enabled"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ WiFi services disabled"
fi

# Check 4: Ethernet priority
echo ""
echo "4. Checking Ethernet priority..."
if [ -f "$NM_CONN_DIR/Ethernet.nmconnection" ]; then
    if grep -q "autoconnect-priority=200" "$NM_CONN_DIR/Ethernet.nmconnection" 2>/dev/null; then
        echo "   ✅ Ethernet priority set to 200"
    else
        echo "   ❌ Ethernet priority NOT set to 200"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ Ethernet.nmconnection not found"
    ERRORS=$((ERRORS + 1))
fi

# Check 5: WiFi connections disabled
echo ""
echo "5. Checking WiFi NetworkManager connections..."
WIFI_CONNECTIONS=$(find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "type=wifi\|802-11-wireless\|wlan0" {} \; 2>/dev/null | wc -l | tr -d ' ')
if [ "$WIFI_CONNECTIONS" -gt 0 ]; then
    echo "   Found $WIFI_CONNECTIONS WiFi connection(s), checking if disabled..."
    find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "type=wifi\|802-11-wireless\|wlan0" {} \; 2>/dev/null | while read file; do
        if grep -q "autoconnect=true" "$file" 2>/dev/null; then
            echo "   ❌ $(basename "$file") still has autoconnect=true"
            ERRORS=$((ERRORS + 1))
        elif grep -q "autoconnect-priority=[1-9]" "$file" 2>/dev/null; then
            PRIORITY=$(grep "autoconnect-priority=" "$file" | head -1 | grep -oE "[0-9]+")
            if [ "$PRIORITY" -gt 0 ]; then
                echo "   ❌ $(basename "$file") has priority=$PRIORITY (should be 0)"
                ERRORS=$((ERRORS + 1))
            fi
        else
            echo "   ✅ $(basename "$file") disabled"
        fi
    done
else
    echo "   ✅ No WiFi connections found"
fi

# Check 6: Duplicate eth0-dhcp connection removed
echo ""
echo "6. Checking for duplicate Ethernet connections..."
if [ -f "$NM_CONN_DIR/eth0-dhcp.nmconnection" ]; then
    echo "   ❌ Duplicate eth0-dhcp.nmconnection still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ No duplicate Ethernet connection found"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
if [ $ERRORS -eq 0 ]; then
    echo "║  ✅ ALL CHECKS PASSED                                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    exit 0
else
    echo "║  ❌ FOUND $ERRORS ERROR(S) - RUN FIX_NETWORK_PRECISE.sh    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    exit 1
fi

