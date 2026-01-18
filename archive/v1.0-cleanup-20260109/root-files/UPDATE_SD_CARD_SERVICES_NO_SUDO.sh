#!/bin/bash
# Update SD card with new service names (chronological order)
# This version tries to avoid sudo where possible

set -e

echo "=== UPDATING SD CARD WITH NEW SERVICE NAMES ==="
echo ""

# Check if SD card is mounted
if [ ! -d "/Volumes/rootfs/lib/systemd/system" ]; then
    echo "❌ SD card rootfs not mounted at /Volumes/rootfs"
    echo ""
    echo "Please mount the SD card first:"
    echo "  diskutil list"
    echo "  diskutil mount diskXs2  # rootfs (may need sudo)"
    exit 1
fi

ROOTFS="/Volumes/rootfs"
SOURCE_DIR="$HOME/moodeaudio-cursor/moode-source/lib/systemd/system"

# Check if we can write without sudo
if [ -w "$ROOTFS/lib/systemd/system" ]; then
    USE_SUDO=false
    echo "✅ SD card is writable (no sudo needed)"
else
    USE_SUDO=true
    echo "⚠️  SD card requires sudo for writing"
    echo ""
    echo "You may be prompted for your password."
fi

echo ""

# Copy new services
echo "Copying new services..."
for service in 00-boot-network-ssh 01-ssh-enable 02-eth0-configure; do
    if [ -f "$SOURCE_DIR/${service}.service" ]; then
        if [ "$USE_SUDO" = "true" ]; then
            sudo cp "$SOURCE_DIR/${service}.service" "$ROOTFS/lib/systemd/system/"
        else
            cp "$SOURCE_DIR/${service}.service" "$ROOTFS/lib/systemd/system/"
        fi
        echo "  ✅ Copied ${service}.service"
    else
        echo "  ❌ Source not found: ${service}.service"
    fi
done

echo ""

# Enable new services
echo "Enabling new services..."
if [ "$USE_SUDO" = "true" ]; then
    sudo mkdir -p "$ROOTFS/etc/systemd/system/local-fs.target.wants" 2>/dev/null || true
else
    mkdir -p "$ROOTFS/etc/systemd/system/local-fs.target.wants" 2>/dev/null || true
fi

for service in 00-boot-network-ssh 01-ssh-enable 02-eth0-configure; do
    if [ -f "$ROOTFS/lib/systemd/system/${service}.service" ]; then
        if [ "$USE_SUDO" = "true" ]; then
            sudo ln -sf "/lib/systemd/system/${service}.service" \
                "$ROOTFS/etc/systemd/system/local-fs.target.wants/${service}.service" 2>/dev/null || true
        else
            ln -sf "/lib/systemd/system/${service}.service" \
                "$ROOTFS/etc/systemd/system/local-fs.target.wants/${service}.service" 2>/dev/null || true
        fi
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

