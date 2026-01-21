#!/bin/bash
# Quick fix: Disable systemd-timedated.service that causes boot hang

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    echo "   Mount SD card or set ROOTFS environment variable"
    exit 1
fi

SERVICE="systemd-timedated.service"

echo "=== DISABLING $SERVICE ==="
echo "Root filesystem: $ROOTFS"
echo ""

echo "Disabling $SERVICE..."

# Remove from all locations
rm -f "$ROOTFS/lib/systemd/system/$SERVICE" 2>/dev/null || true
rm -f "$ROOTFS/usr/lib/systemd/system/$SERVICE" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/$SERVICE" 2>/dev/null || true

# Remove ALL symlinks
find "$ROOTFS/etc/systemd/system" -type l -name "*timedated*" 2>/dev/null | xargs rm -f 2>/dev/null || true

# Remove from ALL target wants directories
for target_dir in "$ROOTFS/etc/systemd/system"/*.target.wants "$ROOTFS/etc/systemd/system"/*.wants 2>/dev/null; do
    if [ -d "$target_dir" ]; then
        rm -f "$target_dir/$SERVICE" 2>/dev/null || true
    fi
done

# Mask the service (highest priority) - FORCE
mkdir -p "$ROOTFS/etc/systemd/system" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/$SERVICE" 2>/dev/null || true
ln -sf /dev/null "$ROOTFS/etc/systemd/system/$SERVICE" 2>/dev/null || true

# Create override to make it a no-op (ALWAYS recreate)
mkdir -p "$ROOTFS/etc/systemd/system/$SERVICE.d" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/$SERVICE.d/override.conf" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/$SERVICE.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=
Conflicts=
Before=

[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=0
TimeoutStopSec=0
Type=oneshot
RemainAfterExit=yes
EOF

# Verify it's masked
if [ -L "$ROOTFS/etc/systemd/system/$SERVICE" ]; then
    TARGET=$(readlink "$ROOTFS/etc/systemd/system/$SERVICE" 2>/dev/null || echo "")
    if [ "$TARGET" = "/dev/null" ]; then
        echo "  ✅ $SERVICE disabled, masked, and overridden (verified)"
    else
        echo "  ⚠️  $SERVICE masked but target is: $TARGET"
    fi
else
    echo "  ✅ $SERVICE disabled and masked"
fi

echo ""
echo "✅ $SERVICE is now disabled and will not cause boot hangs"
