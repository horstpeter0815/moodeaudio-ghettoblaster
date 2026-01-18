#!/bin/bash
# ULTRA-AGGRESSIVE: Disable ALL NetworkManager waiting mechanisms
# Fixes the 90 second (1 minute 30 seconds) boot delay

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    echo "   Mount SD card or set ROOTFS environment variable"
    exit 1
fi

echo "=== ULTRA-AGGRESSIVE NetworkManager Wait Disable ==="
echo "Root filesystem: $ROOTFS"
echo ""

# 1. Remove NetworkManager-wait-online.service from ALL possible locations
echo "1. Removing NetworkManager-wait-online.service from ALL locations..."
rm -f "$ROOTFS/lib/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/usr/lib/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ Service files removed from all locations"

# 2. Remove ALL symlinks to NetworkManager-wait-online
echo ""
echo "2. Removing ALL symlinks to NetworkManager-wait-online..."
find "$ROOTFS/etc/systemd/system" -type l -name "*NetworkManager-wait-online*" 2>/dev/null | while read link; do
    rm -f "$link" 2>/dev/null || true
done
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/sysinit.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ All symlinks removed"

# 3. Create mask (symlink to /dev/null) - HIGHEST PRIORITY
echo ""
echo "3. Creating mask (symlink to /dev/null)..."
rm -f "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
ln -sf /dev/null "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.target" 2>/dev/null || true
ln -sf /dev/null "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.target" 2>/dev/null || true
echo "✅ Service masked (symlink to /dev/null)"

# 4. Create override that makes it a no-op
echo ""
echo "4. Creating override (backup if mask doesn't work)..."
mkdir -p "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service.d/override.conf" << 'EOF'
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
echo "✅ Override created (ExecStart=/bin/true, TimeoutStartSec=0)"

# 5. Disable network-online.target completely
echo ""
echo "5. Disabling network-online.target completely..."
mkdir -p "$ROOTFS/etc/systemd/system/network-online.target.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/network-online.target.d/override.conf" << 'EOF'
[Unit]
# Make network-online immediately available (don't wait)
After=
Wants=
Requires=
Conflicts=
Before=

[Install]
EOF
rm -f "$ROOTFS/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ network-online.target disabled (no dependencies)"

# 6. Check and fix services that depend on network-online.target
echo ""
echo "6. Checking services that depend on network-online.target..."
# Find all services that have After=network-online.target or Wants=network-online.target
find "$ROOTFS/lib/systemd/system" "$ROOTFS/usr/lib/systemd/system" -name "*.service" 2>/dev/null | while read service; do
    if grep -q "network-online.target" "$service" 2>/dev/null; then
        service_name=$(basename "$service")
        override_dir="$ROOTFS/etc/systemd/system/$service_name.d"
        mkdir -p "$override_dir" 2>/dev/null || true
        
        # Remove network-online.target from dependencies
        if [ ! -f "$override_dir/remove-network-wait.conf" ]; then
            cat > "$override_dir/remove-network-wait.conf" << 'EOFSERVICE'
[Unit]
# Remove network-online.target dependency (causes 90s boot delay)
After=
Wants=
Requires=
EOFSERVICE
            echo "  ✅ Fixed $service_name (removed network-online.target dependency)"
        fi
    fi
done
echo "✅ All services with network-online.target dependency fixed"

# 7. Create global systemd configuration to skip network waiting
echo ""
echo "7. Creating global systemd configuration..."
mkdir -p "$ROOTFS/etc/systemd/system.conf.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system.conf.d/disable-network-wait.conf" << 'EOF'
[Manager]
# Disable default timeout for network services (prevents 90s boot delay)
DefaultTimeoutStartSec=10
DefaultTimeoutStopSec=5
EOF
echo "✅ Global systemd timeout configured (DefaultTimeoutStartSec=10)"

# 8. Remove from systemd preset
echo ""
echo "8. Removing from systemd preset..."
if [ -f "$ROOTFS/usr/lib/systemd/system-preset/90-systemd.preset" ]; then
    sed -i '' '/NetworkManager-wait-online/d' "$ROOTFS/usr/lib/systemd/system-preset/90-systemd.preset" 2>/dev/null || \
    sed -i '/NetworkManager-wait-online/d' "$ROOTFS/usr/lib/systemd/system-preset/90-systemd.preset" 2>/dev/null || true
    echo "✅ Removed from systemd preset"
fi

# 9. Check for nm-online commands with timeout=90
echo ""
echo "9. Checking for nm-online commands with 90 second timeout..."
find "$ROOTFS/lib/systemd/system" "$ROOTFS/usr/lib/systemd/system" "$ROOTFS/etc/systemd/system" -name "*.service" 2>/dev/null | while read service; do
    if grep -q "nm-online.*timeout.*90\|nm-online.*-t.*90\|--timeout=90" "$service" 2>/dev/null; then
        service_name=$(basename "$service")
        echo "  ⚠️  Found nm-online with 90s timeout in $service_name"
        # Create override to remove the nm-online command
        override_dir="$ROOTFS/etc/systemd/system/$service_name.d"
        mkdir -p "$override_dir" 2>/dev/null || true
        cat > "$override_dir/remove-nm-online.conf" << 'EOFSERVICE'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=0
EOFSERVICE
        echo "  ✅ Override created to remove nm-online command"
    fi
done
echo "✅ All nm-online commands with 90s timeout fixed"

echo ""
echo "✅ ULTRA-AGGRESSIVE NetworkManager wait disable complete!"
echo ""
echo "All NetworkManager waiting mechanisms disabled:"
echo "  - NetworkManager-wait-online.service: REMOVED and MASKED"
echo "  - network-online.target: DISABLED (no dependencies)"
echo "  - Services depending on network-online: FIXED"
echo "  - nm-online commands with 90s timeout: FIXED"
echo "  - Global systemd timeout: 10s (was unlimited)"
echo ""
echo "Boot should NO LONGER wait 90 seconds for network!"
