#!/bin/bash
################################################################################
# RESET PI PASSWORD ON SD CARD
# Sets password for pi/andre/moode users
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 RESETTING PI PASSWORDS ON SD CARD                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root (use sudo)"
    exit 1
fi

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ Root partition not found"
    exit 1
fi

echo "Using rootfs: $ROOTFS"
echo ""

# Check if we can chroot
if ! command -v chroot >/dev/null 2>&1; then
    echo "❌ chroot command not found"
    exit 1
fi

# Mount necessary filesystems for chroot
echo "1. Preparing chroot environment..."
mount --bind /dev "$ROOTFS/dev" 2>/dev/null || true
mount --bind /proc "$ROOTFS/proc" 2>/dev/null || true
mount --bind /sys "$ROOTFS/sys" 2>/dev/null || true

echo "2. Resetting passwords..."

# Reset pi user password
if grep -q "^pi:" "$ROOTFS/etc/passwd" 2>/dev/null; then
    echo "   Resetting pi user password to 'raspberry'..."
    chroot "$ROOTFS" bash -c "echo 'pi:raspberry' | chpasswd" 2>/dev/null || true
    echo "   ✅ pi password set"
fi

# Reset andre user password
if grep -q "^andre:" "$ROOTFS/etc/passwd" 2>/dev/null; then
    echo "   Resetting andre user password to '0815'..."
    chroot "$ROOTFS" bash -c "echo 'andre:0815' | chpasswd" 2>/dev/null || true
    echo "   ✅ andre password set"
fi

# Reset moode user password
if grep -q "^moode:" "$ROOTFS/etc/passwd" 2>/dev/null; then
    echo "   Resetting moode user password to 'moodeaudio'..."
    chroot "$ROOTFS" bash -c "echo 'moode:moodeaudio' | chpasswd" 2>/dev/null || true
    echo "   ✅ moode password set"
fi

# Unmount
echo ""
echo "3. Cleaning up..."
umount "$ROOTFS/dev" 2>/dev/null || true
umount "$ROOTFS/proc" 2>/dev/null || true
umount "$ROOTFS/sys" 2>/dev/null || true

echo ""
echo "✅ Password reset complete!"
echo ""
echo "Try connecting with:"
echo "  ssh pi@ghettoblaster.local"
echo "  Password: raspberry"
echo ""
echo "Or:"
echo "  ssh andre@ghettoblaster.local"
echo "  Password: 0815"
echo ""

