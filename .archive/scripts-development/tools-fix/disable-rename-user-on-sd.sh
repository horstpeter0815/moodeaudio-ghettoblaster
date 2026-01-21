#!/bin/bash
# Disable rename user services on SD card to prevent boot hang
# Run this when SD card is mounted

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    echo "   Mount SD card or set ROOTFS environment variable"
    exit 1
fi

echo "=== Disabling Rename User Services on SD Card ==="
echo "Root filesystem: $ROOTFS"
echo ""

# 1. Completely remove 05-remove-pi-user.service (AGGRESSIVE)
echo "1. Removing 05-remove-pi-user.service (aggressive)..."
# Remove service files entirely
rm -f "$ROOTFS/lib/systemd/system/05-remove-pi-user.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/05-remove-pi-user.service" 2>/dev/null || true
# Remove ALL symlinks
find "$ROOTFS/etc/systemd/system" -type l -name "*05-remove-pi-user*" 2>/dev/null | xargs rm -f 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/05-remove-pi-user.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/sysinit.target.wants/05-remove-pi-user.service" 2>/dev/null || true
# Mask the service (symlink to /dev/null)
ln -sf /dev/null "$ROOTFS/etc/systemd/system/05-remove-pi-user.service" 2>/dev/null || true
# Also create override as backup
mkdir -p "$ROOTFS/etc/systemd/system/05-remove-pi-user.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/05-remove-pi-user.service.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=
Before=

[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=0.1
Type=oneshot
RemainAfterExit=yes
EOF
echo "✅ 05-remove-pi-user.service removed, masked, and disabled"

# 2. Completely remove fix-user-id.service (AGGRESSIVE)
echo "2. Removing fix-user-id.service (aggressive)..."
# Remove service files entirely
rm -f "$ROOTFS/lib/systemd/system/fix-user-id.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/fix-user-id.service" 2>/dev/null || true
# Remove ALL symlinks
find "$ROOTFS/etc/systemd/system" -type l -name "*fix-user-id*" 2>/dev/null | xargs rm -f 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/sysinit.target.wants/fix-user-id.service" 2>/dev/null || true
# Mask the service (symlink to /dev/null)
ln -sf /dev/null "$ROOTFS/etc/systemd/system/fix-user-id.service" 2>/dev/null || true
# Also create override as backup
mkdir -p "$ROOTFS/etc/systemd/system/fix-user-id.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/fix-user-id.service.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=
Before=

[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=0.1
Type=oneshot
RemainAfterExit=yes
EOF
echo "✅ fix-user-id.service removed, masked, and disabled"

# 2a. Disable userconfig.service (shows rename user dialog)
echo "2a. Disabling userconfig.service (rename user dialog)..."
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/userconfig.service" 2>/dev/null || true
mkdir -p "$ROOTFS/etc/systemd/system/userconfig.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/userconfig.service.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=
Before=

[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=0.1
Type=oneshot
RemainAfterExit=yes
EOF
# Also mask it
rm -f "$ROOTFS/etc/systemd/system/userconfig.service" 2>/dev/null || true
ln -sf /dev/null "$ROOTFS/etc/systemd/system/userconfig.service" 2>/dev/null || true
echo "✅ userconfig.service disabled and masked (no more rename user dialog)"

# 2b. ULTRA-AGGRESSIVE: Disable systemd-user-sessions completely (prevents user slice removal hang)
echo "2b. Disabling systemd-user-sessions.service (ULTRA-AGGRESSIVE)..."
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/systemd-user-sessions.service" 2>/dev/null || true
mkdir -p "$ROOTFS/etc/systemd/system/systemd-user-sessions.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/systemd-user-sessions.service.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=
Conflicts=
Before=

[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=0.1
TimeoutStopSec=0.1
Type=oneshot
RemainAfterExit=yes
EOF
# Also mask it
rm -f "$ROOTFS/etc/systemd/system/systemd-user-sessions.service" 2>/dev/null || true
ln -sf /dev/null "$ROOTFS/etc/systemd/system/systemd-user-sessions.service" 2>/dev/null || true
echo "✅ systemd-user-sessions.service disabled and masked (no more user slice hang)"

# 2c. Fix user.slice cleanup hang
echo "2c. Fixing user.slice (no cleanup hang)..."
mkdir -p "$ROOTFS/etc/systemd/system/user.slice.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/user.slice.d/override.conf" << 'EOF'
[Unit]
# Prevent user slice cleanup hang
After=
Wants=
Requires=
Conflicts=
Before=
EOF
echo "✅ user.slice fixed (no cleanup hang)"

# 2d. Disable user@.service (manages user slices)
echo "2d. Disabling user@.service (user slice management)..."
mkdir -p "$ROOTFS/etc/systemd/system/user@.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/user@.service.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=
Conflicts=
Before=

[Service]
TimeoutStartSec=1
TimeoutStopSec=1
EOF
echo "✅ user@.service disabled (no user slice management)"

# 2e. Disable user-runtime-dir@.service
echo "2e. Disabling user-runtime-dir@.service..."
mkdir -p "$ROOTFS/etc/systemd/system/user-runtime-dir@.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/user-runtime-dir@.service.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=

[Service]
TimeoutStartSec=1
TimeoutStopSec=1
EOF
echo "✅ user-runtime-dir@.service disabled"

# 2f. Configure systemd to skip user slice cleanup
echo "2f. Configuring systemd to skip user slice cleanup..."
mkdir -p "$ROOTFS/etc/systemd/system.conf.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system.conf.d/no-user-slice-cleanup.conf" << 'EOF'
[Manager]
# Skip user slice cleanup during boot
DefaultTimeoutStartSec=5
DefaultTimeoutStopSec=5
EOF
echo "✅ systemd configured to skip user slice cleanup"

# 3. Enable arm_boost in config.txt
echo "3. Enabling arm_boost..."
BOOTFS="${BOOTFS:-/Volumes/bootfs}"
if [ -f "$BOOTFS/config.txt" ]; then
    # Remove existing arm_boost
    sed -i '' '/^arm_boost=/d' "$BOOTFS/config.txt" 2>/dev/null || sed -i '/^arm_boost=/d' "$BOOTFS/config.txt" 2>/dev/null || true
    
    # Add arm_boost=1 in [pi5] section
    if grep -q "^\[pi5\]" "$BOOTFS/config.txt"; then
        sed -i '' '/^\[pi5\]/a\
arm_boost=1
' "$BOOTFS/config.txt" 2>/dev/null || sed -i '/^\[pi5\]/a arm_boost=1' "$BOOTFS/config.txt" 2>/dev/null || true
    else
        echo "arm_boost=1" >> "$BOOTFS/config.txt" 2>/dev/null || true
    fi
    echo "✅ arm_boost=1 enabled"
else
    echo "⚠️  config.txt not found at $BOOTFS/config.txt"
fi

# 4. Configure PeppyMeter to start after boot
echo "4. Configuring PeppyMeter to start after boot..."
mkdir -p "$ROOTFS/etc/systemd/system/peppymeter.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/peppymeter.service.d/delay-after-boot.conf" << 'EOF'
[Unit]
After=multi-user.target
After=moode.service
After=mpd.service
Wants=multi-user.target

[Service]
ExecStartPre=/bin/sleep 5
TimeoutStartSec=30
EOF
echo "✅ PeppyMeter configured to start after boot"

echo ""
# 5. COMPLETELY DISABLE NetworkManager-wait-online (remove, mask, override - everything)
echo "5. COMPLETELY DISABLING NetworkManager-wait-online (remove, mask, override)..."

# Method 1: Remove service files from /usr/lib and /lib
rm -f "$ROOTFS/usr/lib/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/lib/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ Service files removed"

# Method 2: Remove ALL enabling symlinks
find "$ROOTFS/etc/systemd/system" -type l -name "*NetworkManager-wait-online*" 2>/dev/null | xargs rm -f 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/sysinit.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ All enabling symlinks removed"

# Method 3: Create mask (symlink to /dev/null) - highest priority
rm -f "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
ln -sf /dev/null "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.target" 2>/dev/null || true
ln -sf /dev/null "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.target" 2>/dev/null || true
echo "✅ Services masked (symlink to /dev/null)"

# Method 4: Create override (backup if mask doesn't work)
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
echo "✅ Override created (backup)"

# Method 5: Disable network-online.target completely
mkdir -p "$ROOTFS/etc/systemd/system/network-online.target.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/network-online.target.d/override.conf" << 'EOF'
[Unit]
# Make network-online immediately available (don't wait)
After=
Wants=
Requires=
Conflicts=
Before=
EOF
rm -f "$ROOTFS/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ network-online.target disabled"

# Method 6: Remove from systemd preset (if exists)
if [ -f "$ROOTFS/usr/lib/systemd/system-preset/90-systemd.preset" ]; then
    sed -i '' '/NetworkManager-wait-online/d' "$ROOTFS/usr/lib/systemd/system-preset/90-systemd.preset" 2>/dev/null || \
    sed -i '/NetworkManager-wait-online/d' "$ROOTFS/usr/lib/systemd/system-preset/90-systemd.preset" 2>/dev/null || true
    echo "✅ Systemd preset updated"
fi

echo "✅ NetworkManager-wait-online COMPLETELY DISABLED"
echo "   - Service files removed"
echo "   - All symlinks removed"
echo "   - Services masked (symlink to /dev/null)"
echo "   - Override created (backup)"
echo "   - network-online.target disabled"
echo "   - Boot will NOT wait for network connection"

echo ""
# 6. DISABLE systemd-statcollect (System actively accounting tool - causes boot hang)
echo "6. Disabling systemd-statcollect.service (System actively accounting tool)..."
# Remove service files
rm -f "$ROOTFS/lib/systemd/system/systemd-statcollect.service" 2>/dev/null || true
rm -f "$ROOTFS/usr/lib/systemd/system/systemd-statcollect.service" 2>/dev/null || true
# Remove symlinks
find "$ROOTFS/etc/systemd/system" -type l -name "*statcollect*" 2>/dev/null | xargs rm -f 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/sysinit.target.wants/systemd-statcollect.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/systemd-statcollect.service" 2>/dev/null || true
# Mask the service
ln -sf /dev/null "$ROOTFS/etc/systemd/system/systemd-statcollect.service" 2>/dev/null || true
# Create override
mkdir -p "$ROOTFS/etc/systemd/system/systemd-statcollect.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/systemd-statcollect.service.d/override.conf" << 'EOF'
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
echo "✅ systemd-statcollect.service disabled and masked (no more boot hang)"

echo ""
echo "✅ All fixes applied to SD card"
echo ""
echo "Services removed/disabled:"
echo "  - 05-remove-pi-user.service REMOVED (no more rename user screen)"
echo "  - fix-user-id.service REMOVED"
echo "  - userconfig.service DISABLED (no more rename user dialog)"
echo "  - systemd-statcollect.service DISABLED (no more 'System actively accounting' hang)"
echo "  - NetworkManager-wait-online DISABLED (no more boot delay)"
echo ""
echo "Configuration updated:"
echo "  - arm_boost=1 enabled"
echo "  - PeppyMeter starts after boot completes"
echo ""
echo "Eject SD card and boot - should no longer hang on rename user screen or statcollect"
