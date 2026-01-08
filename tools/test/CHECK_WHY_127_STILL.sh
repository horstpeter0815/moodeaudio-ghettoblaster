#!/bin/bash
################################################################################
# Check why 127.0.1.1 is still happening
################################################################################

echo "Diagnosing 127.0.1.1 issue..."
echo ""

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ SD card not mounted"
    echo ""
    echo "Mount SD card first, then run this again"
    exit 1
fi

echo "SD card: $ROOTFS"
echo ""

# Check 1: Is simple service installed?
echo "1. Checking if simple network service exists..."
if [ -f "$ROOTFS/lib/systemd/system/early-network.service" ]; then
    echo "   ✅ early-network.service exists"
    if [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/early-network.service" ]; then
        echo "   ✅ Service is ENABLED"
    else
        echo "   ❌ Service is NOT enabled!"
    fi
else
    echo "   ❌ early-network.service NOT found"
    echo "   → Need to run: sudo bash SIMPLE_NETWORK_FIX.sh"
fi

# Check 2: Is NetworkManager disabled?
echo ""
echo "2. Checking if NetworkManager is disabled..."
if [ -f "$ROOTFS/etc/systemd/system/NetworkManager.service.d/override.conf" ]; then
    if grep -q "ExecStart=/bin/true" "$ROOTFS/etc/systemd/system/NetworkManager.service.d/override.conf" 2>/dev/null; then
        echo "   ✅ NetworkManager is disabled"
    else
        echo "   ⚠️  NetworkManager override exists but may not be disabled"
    fi
else
    echo "   ❌ NetworkManager is NOT disabled"
    echo "   → Need to run: sudo bash SIMPLE_NETWORK_FIX.sh"
fi

# Check 3: Check cmdline.txt for network issues
echo ""
echo "3. Checking cmdline.txt..."
if [ -f "/Volumes/bootfs/cmdline.txt" ]; then
    if grep -q "ip=" "/Volumes/bootfs/cmdline.txt" 2>/dev/null; then
        IP_CMD=$(grep -o "ip=[^ ]*" "/Volumes/bootfs/cmdline.txt")
        echo "   ⚠️  Found IP configuration in cmdline.txt: $IP_CMD"
        echo "   → This might override our configuration"
    else
        echo "   ✅ No IP configuration in cmdline.txt (good)"
    fi
else
    echo "   ⚠️  cmdline.txt not found"
fi

# Check 4: Check for other network services
echo ""
echo "4. Checking for other network services..."
WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"
OTHER_SERVICES=$(ls -1 "$WANTS_DIR" 2>/dev/null | grep -E "network|eth|wifi|dhcp" | grep -v "early-network" || true)
if [ -n "$OTHER_SERVICES" ]; then
    echo "   ⚠️  Other network services found:"
    echo "$OTHER_SERVICES" | while read svc; do
        echo "      - $svc"
    done
else
    echo "   ✅ No other network services enabled (good)"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SUMMARY                                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f "$ROOTFS/lib/systemd/system/early-network.service" ]; then
    echo "❌ SIMPLE FIX NOT APPLIED"
    echo ""
    echo "Apply the fix now:"
    echo "  sudo bash SIMPLE_NETWORK_FIX.sh"
elif [ ! -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/early-network.service" ]; then
    echo "⚠️  Service exists but NOT enabled"
    echo ""
    echo "Re-run the fix:"
    echo "  sudo bash SIMPLE_NETWORK_FIX.sh"
else
    echo "✅ Simple fix is applied"
    echo ""
    echo "If Pi still shows 127.0.1.1, check on Pi:"
    echo "  journalctl -u early-network.service -n 50"
    echo "  systemctl status early-network.service"
    echo "  ip addr show eth0"
fi
echo ""



