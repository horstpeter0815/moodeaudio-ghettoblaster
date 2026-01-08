#!/bin/bash
# FINISH USB GADGET SETUP - Run with: sudo bash FINISH_USB_SETUP.sh

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FINISHING USB GADGET SETUP                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ Root partition not found"
    exit 1
fi

SERVICE_FILE="$ROOTFS/lib/systemd/system/usb-gadget-network.service"
ENABLE_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"

# 1. Create service file
echo "1. Creating service file..."
mkdir -p "$(dirname "$SERVICE_FILE")"
cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Configure USB Gadget Network Interface
After=network-pre.target
Before=network.target
Wants=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'sleep 2 && if [ -d /sys/class/net/usb0 ]; then ip link set usb0 up && ip addr add 192.168.10.2/24 dev usb0 || true; fi'
ExecStop=/bin/bash -c 'if [ -d /sys/class/net/usb0 ]; then ip link set usb0 down || true; fi'

[Install]
WantedBy=multi-user.target
EOF
chmod 644 "$SERVICE_FILE"
echo "✅ Service file created"

# 2. Enable service
echo "2. Enabling service..."
mkdir -p "$ENABLE_DIR"
ln -sf "/lib/systemd/system/usb-gadget-network.service" \
       "$ENABLE_DIR/usb-gadget-network.service"
echo "✅ Service enabled"

# 3. Verify credentials
echo "3. Checking credentials..."
echo "Users found:"
grep -E "^pi:|^moode:|^andre:" "$ROOTFS/etc/passwd" 2>/dev/null | cut -d: -f1 || echo "No standard users found"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ SETUP COMPLETE!                                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Eject SD card"
echo "  2. Boot Pi with USB cable connected to Mac"
echo "  3. Run: ./SETUP_USB_GADGET_MAC.sh"
echo "  4. Connect: ssh pi@192.168.10.2 (or andre@192.168.10.2)"
echo ""
