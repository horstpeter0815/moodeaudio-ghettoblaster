#!/bin/bash
################################################################################
#
# COMPLETE USB GADGET SETUP - Run this with sudo
#
# Run: sudo bash COMPLETE_USB_SETUP_NOW.sh
#
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔌 COMPLETE USB GADGET SETUP                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find rootfs partition
ROOTFS=""
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ ERROR: Could not find rootfs partition"
    echo "   Please mount SD card and try again"
    exit 1
fi

BOOTFS="/Volumes/bootfs"

echo "✅ Using bootfs: $BOOTFS"
echo "✅ Using rootfs: $ROOTFS"
echo ""

# 1. Create service file
echo "1. Creating USB gadget network service..."
SERVICE_FILE="$ROOTFS/lib/systemd/system/usb-gadget-network.service"
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
echo ""

# 2. Enable service
echo "2. Enabling USB gadget network service..."
ENABLE_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"
mkdir -p "$ENABLE_DIR"
ln -sf "/lib/systemd/system/usb-gadget-network.service" \
       "$ENABLE_DIR/usb-gadget-network.service" 2>/dev/null || true
echo "✅ Service enabled"
echo ""

# 3. Verify config.txt
echo "3. Verifying config.txt..."
if grep -q "dtoverlay=dwc2" "$BOOTFS/config.txt"; then
    echo "✅ USB gadget overlay configured"
else
    echo "⚠️  USB gadget overlay not found in config.txt"
    echo "   Run: ./SETUP_USB_GADGET_STANDARD_MOODE.sh (first part should work)"
fi
echo ""

# 4. Verify cmdline.txt
echo "4. Verifying cmdline.txt..."
if grep -q "modules-load.*g_ether" "$BOOTFS/cmdline.txt"; then
    echo "✅ USB gadget modules configured"
else
    echo "⚠️  USB gadget modules not found in cmdline.txt"
    echo "   Run: ./SETUP_USB_GADGET_STANDARD_MOODE.sh (first part should work)"
fi
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ SETUP COMPLETE!                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Eject SD card"
echo "  2. Boot Pi with USB cable connected to Mac"
echo "  3. Run: ./SETUP_USB_GADGET_MAC.sh"
echo "  4. Connect: ssh pi@192.168.10.2"
echo ""

