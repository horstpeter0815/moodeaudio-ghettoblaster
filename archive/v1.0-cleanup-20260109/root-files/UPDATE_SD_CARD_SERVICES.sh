#!/bin/bash
# Update SD card with new service names (chronological order)

set -e

echo "=== UPDATING SD CARD WITH NEW SERVICE NAMES ==="
echo ""

# Check if SD card is mounted
if [ ! -d "/Volumes/rootfs/lib/systemd/system" ]; then
    echo "❌ SD card rootfs not mounted at /Volumes/rootfs"
    echo ""
    echo "Please mount the SD card first:"
    echo "  diskutil list"
    echo "  sudo diskutil mount diskXs2  # rootfs"
    exit 1
fi

ROOTFS="/Volumes/rootfs"
SOURCE_DIR="$HOME/moodeaudio-cursor/moode-source/lib/systemd/system"

echo "✅ SD card mounted at $ROOTFS"
echo ""

# Copy new services
echo "Copying new services..."
for service in 00-boot-network-ssh 01-ssh-enable 02-eth0-configure; do
    if [ -f "$SOURCE_DIR/${service}.service" ]; then
        cp "$SOURCE_DIR/${service}.service" "$ROOTFS/lib/systemd/system/"
        echo "  ✅ Copied ${service}.service"
    else
        echo "  ❌ Source not found: ${service}.service"
    fi
done

echo ""

# Remove old service names (optional - keep them for now as backup)
echo "Old services found (keeping as backup):"
for old in ssh-guaranteed eth0-direct-static boot-complete-minimal; do
    if [ -f "$ROOTFS/lib/systemd/system/${old}.service" ]; then
        echo "  ⚠️  ${old}.service (will be replaced by new service)"
    fi
done

echo ""

# Enable new services
echo "Enabling new services..."
mkdir -p "$ROOTFS/etc/systemd/system/local-fs.target.wants" 2>/dev/null || true

for service in 00-boot-network-ssh 01-ssh-enable 02-eth0-configure; do
    if [ -f "$ROOTFS/lib/systemd/system/${service}.service" ]; then
        ln -sf "/lib/systemd/system/${service}.service" \
            "$ROOTFS/etc/systemd/system/local-fs.target.wants/${service}.service" 2>/dev/null || true
        echo "  ✅ Enabled ${service}.service"
    fi
done

echo ""

# Verify
echo "=== VERIFICATION ==="
echo ""
for service in 00-boot-network-ssh 01-ssh-enable 02-eth0-configure fix-user-id; do
    if [ -f "$ROOTFS/lib/systemd/system/${service}.service" ]; then
        echo "  ✅ ${service}.service"
        if [ -L "$ROOTFS/etc/systemd/system/local-fs.target.wants/${service}.service" ]; then
            echo "     (enabled)"
        fi
    else
        echo "  ❌ ${service}.service MISSING"
    fi
done

echo ""
echo "✅ SD card updated with new service names!"
echo ""
echo "Services are now:"
echo "  00-boot-network-ssh.service (chronological)"
echo "  01-ssh-enable.service (chronological)"
echo "  02-eth0-configure.service (chronological)"
echo ""
echo "No more status-descriptive names!"

