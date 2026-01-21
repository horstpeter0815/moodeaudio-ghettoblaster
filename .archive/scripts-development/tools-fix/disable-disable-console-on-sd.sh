#!/bin/bash
# Disable disable-console.service on mounted SD card
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect SD card
ROOTFS="${ROOTFS:-/}"

if [ "$ROOTFS" = "/" ] && [ ! -d "/boot/firmware" ]; then
    if [ -d "/Volumes/rootfs" ]; then
        ROOTFS="/Volumes/rootfs"
    else
        echo "❌ SD card not found"
        echo "   Mount SD card at /Volumes/rootfs"
        echo "   Or set ROOTFS environment variable"
        exit 1
    fi
fi

echo "=== DISABLING disable-console.service ON SD CARD ==="
echo ""
echo "Root filesystem: $ROOTFS"
echo ""

# Remove symlinks
echo "1. Removing service symlinks..."
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/disable-console.service" 2>/dev/null || true

# Create override to make it do nothing
echo "2. Creating override to prevent start..."
mkdir -p "$ROOTFS/etc/systemd/system/disable-console.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/disable-console.service.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=1
EOF

echo ""
echo "✅ disable-console.service disabled"
echo "   Service will not run on next boot"
echo ""
