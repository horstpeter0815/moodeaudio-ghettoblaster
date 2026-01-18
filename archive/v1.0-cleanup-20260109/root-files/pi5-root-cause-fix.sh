#!/bin/bash
# PI 5 ROOT CAUSE FIX - FRAMEBUFFER ORIENTATION
# Chief Engineer Solution

set -e

echo "=========================================="
echo "PI 5 ROOT CAUSE FIX"
echo "Framebuffer Orientation Correction"
echo "=========================================="
echo ""

ssh pi2 << 'ROOTFIX'
# Backup
BACKUP_DIR="/home/andre/backup_rootcause_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp /boot/config.txt "$BACKUP_DIR/config.txt.backup" 2>/dev/null || true
sudo cp /boot/cmdline.txt "$BACKUP_DIR/cmdline.txt.backup" 2>/dev/null || true

echo "=== FIX: SET VIDEO MODE IN CMDLINE ==="
# Read current cmdline
CURRENT_CMDLINE=$(cat /boot/cmdline.txt)

# Remove any existing video parameter
NEW_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/video=[^ ]* *//g')

# Add correct video parameter for 1280x400
NEW_CMDLINE="$NEW_CMDLINE video=HDMI-A-1:1280x400@60"

# Write new cmdline
echo "$NEW_CMDLINE" | sudo tee /boot/cmdline.txt > /dev/null

echo "✅ cmdline.txt updated with video parameter"
cat /boot/cmdline.txt

echo ""
echo "=== FIX: UPDATE CONFIG.TXT ==="
# Ensure config.txt has correct settings
sudo tee -a /boot/config.txt > /dev/null << 'EOF'

# Video mode enforcement
video=HDMI-A-1:1280x400@60

EOF

echo "✅ config.txt updated"

echo ""
echo "=== READY FOR REBOOT ==="
ROOTFIX

echo ""
echo "=== REBOOTING ==="
ssh pi2 "sudo reboot" || true

echo "Waiting for reboot..."
sleep 10

MAX_WAIT=90
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        echo "✅ Pi 5 online"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done

echo ""
echo "Waiting for services..."
sleep 35

echo ""
echo "=== VERIFICATION ==="
ssh pi2 << 'VERIFY'
echo "1. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "2. Video parameter in cmdline:"
cat /proc/cmdline | grep -o 'video=[^ ]*' || echo "Not found"

echo ""
echo "3. Display:"
export DISPLAY=:0
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "4. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1
VERIFY

echo ""
echo "=========================================="
echo "ROOT CAUSE FIX APPLIED"
echo "=========================================="

