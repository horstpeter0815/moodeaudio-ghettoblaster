#!/bin/bash
################################################################################
# Check if network mode manager timing fix is applied
################################################################################

echo "Checking if timing fix is applied to SD card..."
echo ""

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ SD card not found"
    exit 1
fi

echo "SD card rootfs: $ROOTFS"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check 1: Service runs before NetworkManager
echo "1. Checking if service runs BEFORE NetworkManager..."
if grep -q "Before=NetworkManager.service" "$ROOTFS/lib/systemd/system/network-mode-manager.service" 2>/dev/null; then
    echo "   ✅ PASS - Service runs before NetworkManager"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "   ❌ FAIL - Service does NOT run before NetworkManager"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 2: Retry mechanism in script
echo ""
echo "2. Checking if retry mechanism is in script..."
if grep -q "RETRY MECHANISM\|Ethernet IP incorrect" "$ROOTFS/usr/local/bin/network-mode-manager.sh" 2>/dev/null; then
    echo "   ✅ PASS - Retry mechanism found"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "   ❌ FAIL - Retry mechanism NOT found"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 3: Network watchdog service exists
echo ""
echo "3. Checking if network watchdog service exists..."
if [ -f "$ROOTFS/lib/systemd/system/network-watchdog.service" ]; then
    if [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/network-watchdog.service" ]; then
        echo "   ✅ PASS - Network watchdog service exists and is enabled"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo "   ⚠️  WARN - Network watchdog exists but not enabled"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
else
    echo "   ❌ FAIL - Network watchdog service NOT found"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 4: NetworkManager autoconnect disabled
echo ""
echo "4. Checking if NetworkManager autoconnect is disabled..."
if grep -q "autoconnect=false" "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" 2>/dev/null; then
    echo "   ✅ PASS - NetworkManager autoconnect is disabled"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "   ❌ FAIL - NetworkManager autoconnect is still enabled"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  CHECK SUMMARY                                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Checks Passed: $CHECKS_PASSED"
echo "Checks Failed: $CHECKS_FAILED"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo "✅ ALL FIXES ARE APPLIED!"
    echo ""
    echo "SD card is ready. Boot the Pi and it should get IP 192.168.10.2"
else
    echo "❌ SOME FIXES ARE MISSING"
    echo ""
    echo "Apply the timing fix:"
    echo "  sudo bash FIX_NETWORK_MODE_MANAGER_TIMING.sh"
fi
echo ""



