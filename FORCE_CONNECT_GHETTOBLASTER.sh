#!/bin/bash
################################################################################
# FORCE CONNECT TO GHETTOBLASTER
# Tries multiple methods to connect
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FORCING CONNECTION TO GHETTOBLASTER                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find IP
PI_IP=$(avahi-resolve -n GhettoBlaster.local 2>/dev/null | awk '{print $2}' || \
        dscacheutil -q host -a name GhettoBlaster.local 2>/dev/null | grep "ip_address" | awk '{print $2}' || \
        echo "")

if [ -z "$PI_IP" ]; then
    echo "⚠️  Could not resolve IP, trying common addresses..."
    for ip in "192.168.10.2" "192.168.1.100" "192.168.178.178"; do
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            PI_IP="$ip"
            break
        fi
    done
fi

if [ -z "$PI_IP" ]; then
    echo "❌ Could not find Pi IP address"
    echo ""
    echo "Please check Finder > Network > GhettoBlaster > Get Info"
    echo "And tell me the IP address shown"
    exit 1
fi

echo "✅ Found Pi at: $PI_IP"
echo ""

# Try mounting with different credentials
CREDS=("pi:raspberry" "andre:0815" "moode:moodeaudio" "pi:moodeaudio")

MOUNT_POINT="/tmp/ghettoblaster_mount"
mkdir -p "$MOUNT_POINT" 2>/dev/null

for cred in "${CREDS[@]}"; do
    USER=$(echo $cred | cut -d: -f1)
    PASS=$(echo $cred | cut -d: -f2)
    
    echo "Trying $USER/$PASS..."
    
    # Unmount any existing mount
    umount "$MOUNT_POINT" 2>/dev/null
    
    # Try to mount
    if mount_smbfs "//$USER:$PASS@$PI_IP/tmp" "$MOUNT_POINT" 2>/dev/null; then
        echo "✅ SUCCESS! Connected with $USER/$PASS"
        echo ""
        echo "Mounted at: $MOUNT_POINT"
        echo ""
        ls -la "$MOUNT_POINT" | head -10
        echo ""
        echo "To unmount: umount $MOUNT_POINT"
        exit 0
    fi
done

echo "❌ All credential attempts failed"
echo ""
echo "The Pi might be:"
echo "  1. SMB service not running"
echo "  2. User doesn't have SMB access"
echo "  3. Firewall blocking"
echo ""
echo "Try SSH instead:"
echo "  ssh pi@$PI_IP"
echo "  Password: raspberry"

