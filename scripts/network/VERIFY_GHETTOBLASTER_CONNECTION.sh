#!/bin/bash
################################################################################
# VERIFY GHETTOBLASTER WIFI CONNECTION CONFIGURATION
# Checks that Pi WiFi client configuration is correct
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

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 VERIFYING GHETTOBLASTER WIFI CONFIGURATION              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0

# Check 1: Ghettoblaster connection exists
echo "1. Checking Ghettoblaster WiFi connection..."
if [ -f "$NM_CONN_DIR/Ghettoblaster.nmconnection" ]; then
    echo "   ✅ Ghettoblaster.nmconnection exists"
    
    # Check SSID
    if grep -q "ssid=Ghettoblaster" "$NM_CONN_DIR/Ghettoblaster.nmconnection" 2>/dev/null; then
        echo "   ✅ SSID is 'Ghettoblaster'"
    else
        echo "   ❌ SSID is NOT 'Ghettoblaster'"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check autoconnect
    if grep -q "autoconnect=true" "$NM_CONN_DIR/Ghettoblaster.nmconnection" 2>/dev/null; then
        echo "   ✅ autoconnect=true"
    else
        echo "   ❌ autoconnect is NOT true"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check priority
    if grep -q "autoconnect-priority=200" "$NM_CONN_DIR/Ghettoblaster.nmconnection" 2>/dev/null; then
        echo "   ✅ Priority is 200 (highest)"
    else
        echo "   ❌ Priority is NOT 200"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check password is set
    if grep -q "psk=" "$NM_CONN_DIR/Ghettoblaster.nmconnection" 2>/dev/null; then
        PSK_LINE=$(grep "psk=" "$NM_CONN_DIR/Ghettoblaster.nmconnection" | head -1)
        if [ -n "$PSK_LINE" ] && [ "$PSK_LINE" != "psk=" ]; then
            echo "   ✅ WiFi password is configured"
        else
            echo "   ❌ WiFi password is NOT configured"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "   ❌ WiFi password section missing"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ Ghettoblaster.nmconnection NOT found"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: Other WiFi connections disabled
echo ""
echo "2. Checking other WiFi connections are disabled..."
OTHER_WIFI=$(find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "type=wifi\|802-11-wireless\|wlan0" {} \; 2>/dev/null | grep -v "Ghettoblaster.nmconnection" | wc -l | tr -d ' ')
if [ "$OTHER_WIFI" -gt 0 ]; then
    echo "   Found $OTHER_WIFI other WiFi connection(s), checking if disabled..."
    find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "type=wifi\|802-11-wireless\|wlan0" {} \; 2>/dev/null | grep -v "Ghettoblaster.nmconnection" | while read file; do
        BASENAME=$(basename "$file")
        if grep -q "autoconnect=true" "$file" 2>/dev/null; then
            echo "   ❌ $BASENAME still has autoconnect=true"
            ERRORS=$((ERRORS + 1))
        elif grep -q "autoconnect-priority=[1-9]" "$file" 2>/dev/null; then
            PRIORITY=$(grep "autoconnect-priority=" "$file" | head -1 | grep -oE "[0-9]+")
            if [ "$PRIORITY" -gt 0 ]; then
                echo "   ❌ $BASENAME has priority=$PRIORITY (should be 0)"
                ERRORS=$((ERRORS + 1))
            fi
        else
            echo "   ✅ $BASENAME disabled"
        fi
    done
else
    echo "   ✅ No other WiFi connections found"
fi

# Check 3: Ethernet priority (if exists)
echo ""
echo "3. Checking Ethernet priority..."
if [ -f "$NM_CONN_DIR/Ethernet.nmconnection" ]; then
    if grep -q "autoconnect-priority=" "$NM_CONN_DIR/Ethernet.nmconnection" 2>/dev/null; then
        ETH_PRIORITY=$(grep "autoconnect-priority=" "$NM_CONN_DIR/Ethernet.nmconnection" | head -1 | grep -oE "[0-9]+")
        if [ "$ETH_PRIORITY" -lt 200 ]; then
            echo "   ✅ Ethernet priority is $ETH_PRIORITY (lower than WiFi)"
        else
            echo "   ⚠️  Ethernet priority is $ETH_PRIORITY (same or higher than WiFi)"
        fi
    else
        echo "   ℹ️  Ethernet connection exists but no priority set"
    fi
else
    echo "   ℹ️  No Ethernet connection found (WiFi only mode)"
fi

# Check 4: WiFi services not disabled
echo ""
echo "4. Checking WiFi services..."
if [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/wpa_supplicant.service" ]; then
    echo "   ⚠️  wpa_supplicant.service is enabled (NetworkManager should handle WiFi)"
else
    echo "   ✅ wpa_supplicant not enabled (NetworkManager will handle WiFi)"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
if [ $ERRORS -eq 0 ]; then
    echo "║  ✅ ALL CHECKS PASSED                                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Pi is configured to connect to 'Ghettoblaster' WiFi network."
    echo "After boot, it should automatically connect and get internet from Mac."
    exit 0
else
    echo "║  ❌ FOUND $ERRORS ERROR(S)                                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Please run SETUP_GHETTOBLASTER_WIFI_CLIENT.sh to fix issues."
    exit 1
fi

