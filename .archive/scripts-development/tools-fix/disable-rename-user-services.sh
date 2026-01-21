#!/bin/bash
# Disable services that cause "rename user" screen during boot
# Can be run on Pi or applied to SD card

set -e

ROOTFS="${ROOTFS:-/}"

echo "=== Disabling Rename User Services ==="
echo "Root filesystem: $ROOTFS"
echo ""

# 1. Disable 05-remove-pi-user.service
echo "1. Disabling 05-remove-pi-user.service..."
if [ -f "$ROOTFS/lib/systemd/system/05-remove-pi-user.service" ] || [ -f "$ROOTFS/etc/systemd/system/05-remove-pi-user.service" ]; then
    # Remove from multi-user.target.wants
    rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/05-remove-pi-user.service" 2>/dev/null || true
    
    # Create override to disable
    mkdir -p "$ROOTFS/etc/systemd/system/05-remove-pi-user.service.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/05-remove-pi-user.service.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=1
EOF
    
    # Mask the service
    rm -f "$ROOTFS/etc/systemd/system/05-remove-pi-user.service" 2>/dev/null || true
    ln -sf /dev/null "$ROOTFS/etc/systemd/system/05-remove-pi-user.service" 2>/dev/null || true
    
    echo "✅ 05-remove-pi-user.service disabled"
else
    echo "⚠️  05-remove-pi-user.service not found"
fi

# 2. Disable fix-user-id.service
echo "2. Disabling fix-user-id.service..."
if [ -f "$ROOTFS/lib/systemd/system/fix-user-id.service" ] || [ -f "$ROOTFS/etc/systemd/system/fix-user-id.service" ]; then
    # Remove from multi-user.target.wants
    rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
    
    # Create override to disable
    mkdir -p "$ROOTFS/etc/systemd/system/fix-user-id.service.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/fix-user-id.service.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=1
EOF
    
    # Mask the service
    rm -f "$ROOTFS/etc/systemd/system/fix-user-id.service" 2>/dev/null || true
    ln -sf /dev/null "$ROOTFS/etc/systemd/system/fix-user-id.service" 2>/dev/null || true
    
    echo "✅ fix-user-id.service disabled"
else
    echo "⚠️  fix-user-id.service not found"
fi

echo ""
echo "✅ All rename user services disabled"
echo ""
echo "If running on Pi, reload systemd:"
echo "  sudo systemctl daemon-reload"
echo ""
echo "If applied to SD card, the fix will take effect on next boot."
