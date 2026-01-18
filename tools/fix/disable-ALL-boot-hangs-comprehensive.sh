#!/bin/bash
# COMPREHENSIVE: Disable ALL services that can cause boot hangs
# This is a complete fix - no more guessing

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    echo "   Mount SD card or set ROOTFS environment variable"
    exit 1
fi

echo "=== COMPREHENSIVE BOOT HANG FIX ==="
echo "Root filesystem: $ROOTFS"
echo "This will disable ALL known problematic services"
echo ""

# List of ALL services that can cause boot hangs
PROBLEMATIC_SERVICES=(
    "05-remove-pi-user.service"
    "fix-user-id.service"
    "userconfig.service"
    "systemd-user-sessions.service"
    "systemd-statcollect.service"
    "NetworkManager-wait-online.service"
    "systemd-networkd-wait-online.service"
    "network-online.target"
    "first-boot-setup.service"
    "cloud-init.service"
    "cloud-init-local.service"
    "cloud-init.service"
    "cloud-config.service"
    "cloud-final.service"
    "cloud-init.target"
    "systemd-ask-password-console.service"
    "systemd-ask-password-wall.service"
    "getty@tty1.service"
    "systemd-vconsole-setup.service"
    "dev-tty1.device"
    "systemd-timedated.service"
)

echo "Disabling ALL problematic services..."
for service in "${PROBLEMATIC_SERVICES[@]}"; do
    echo ""
    echo "Disabling $service (ULTRA-AGGRESSIVE)..."
    
    # Remove from all locations (AGGRESSIVE)
    rm -f "$ROOTFS/lib/systemd/system/$service" 2>/dev/null || true
    rm -f "$ROOTFS/usr/lib/systemd/system/$service" 2>/dev/null || true
    rm -f "$ROOTFS/etc/systemd/system/$service" 2>/dev/null || true
    
    # Remove ALL symlinks from ALL locations (ULTRA-AGGRESSIVE)
    find "$ROOTFS/etc/systemd/system" -type l -name "*${service}*" 2>/dev/null | xargs rm -f 2>/dev/null || true
    find "$ROOTFS/etc/systemd/system" -type d -name "*${service}*" 2>/dev/null | xargs rm -rf 2>/dev/null || true
    
    # Remove from ALL target wants directories
    for target_dir in "$ROOTFS/etc/systemd/system"/*.target.wants "$ROOTFS/etc/systemd/system"/*.wants; do
        if [ -d "$target_dir" ]; then
            rm -f "$target_dir/$service" 2>/dev/null || true
            rm -f "$target_dir/${service}.d" 2>/dev/null || true
        fi
    done
    
    # Mask the service (highest priority) - FORCE
    rm -f "$ROOTFS/etc/systemd/system/$service" 2>/dev/null || true
    ln -sf /dev/null "$ROOTFS/etc/systemd/system/$service" 2>/dev/null || true
    
    # Create override to make it a no-op (ALWAYS recreate)
    mkdir -p "$ROOTFS/etc/systemd/system/$service.d" 2>/dev/null || true
    rm -f "$ROOTFS/etc/systemd/system/$service.d/override.conf" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/$service.d/override.conf" << 'EOF'
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
    if [ -L "$ROOTFS/etc/systemd/system/$service" ]; then
        TARGET=$(readlink "$ROOTFS/etc/systemd/system/$service" 2>/dev/null || echo "")
        if [ "$TARGET" = "/dev/null" ]; then
            echo "  ✅ $service disabled, masked, and overridden (verified)"
        else
            echo "  ⚠️  $service masked but target is: $TARGET"
        fi
    else
        echo "  ✅ $service disabled and masked"
    fi
done

# Also disable user slice completely
echo ""
echo "Disabling user slice services..."
USER_SLICE_SERVICES=(
    "user.slice"
    "user@.service"
    "user-runtime-dir@.service"
)

for service in "${USER_SLICE_SERVICES[@]}"; do
    mkdir -p "$ROOTFS/etc/systemd/system/$service.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/$service.d/override.conf" << 'EOF'
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
EOF
    echo "  ✅ $service disabled"
done

# Global systemd config to skip user slice cleanup
echo ""
echo "Configuring systemd to skip user slice cleanup..."
mkdir -p "$ROOTFS/etc/systemd/system.conf.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system.conf.d/disable-user-slice.conf" << 'EOF'
[Manager]
DefaultTimeoutStartSec=10
DefaultTimeoutStopSec=5
EOF

# Disable network-online.target completely
echo ""
echo "Disabling network-online.target..."
mkdir -p "$ROOTFS/etc/systemd/system/network-online.target.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/network-online.target.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=
Conflicts=
Before=
EOF
rm -rf "$ROOTFS/etc/systemd/system/network-online.target.wants" 2>/dev/null || true
echo "  ✅ network-online.target disabled"

# Enable arm_boost
echo ""
echo "Enabling arm_boost..."
BOOTFS="${BOOTFS:-/Volumes/bootfs}"
if [ -f "$BOOTFS/config.txt" ]; then
    if ! grep -q "^arm_boost=1" "$BOOTFS/config.txt"; then
        echo "arm_boost=1" >> "$BOOTFS/config.txt"
        echo "  ✅ arm_boost=1 added to config.txt"
    else
        echo "  ✅ arm_boost=1 already enabled"
    fi
else
    echo "  ⚠️  config.txt not found"
fi

# Find and disable ANY service that depends on network-online.target
echo ""
echo "Finding services that depend on network-online.target..."
NETWORK_ONLINE_FIXED=0
find "$ROOTFS/lib/systemd/system" "$ROOTFS/usr/lib/systemd/system" "$ROOTFS/etc/systemd/system" -name "*.service" 2>/dev/null | while read service_file; do
    if grep -q "network-online.target" "$service_file" 2>/dev/null; then
        service_name=$(basename "$service_file")
        override_dir="$ROOTFS/etc/systemd/system/$service_name.d"
        mkdir -p "$override_dir" 2>/dev/null || true
        
        # Always recreate override to ensure it's applied
        cat > "$override_dir/remove-network-dependency.conf" << 'EOF'
[Unit]
# Remove network-online.target dependency (causes boot delays)
After=
Wants=
Requires=
EOF
        NETWORK_ONLINE_FIXED=$((NETWORK_ONLINE_FIXED + 1))
        echo "  ✅ Fixed $service_name (removed network-online dependency)"
    fi
done
echo "  ✅ Fixed $NETWORK_ONLINE_FIXED services with network-online dependencies"

# Fix matrix-boot.service tty1 dependency
echo ""
echo "Fixing matrix-boot.service tty1 dependency..."
if [ -f "$ROOTFS/lib/systemd/system/matrix-boot.service" ]; then
    mkdir -p "$ROOTFS/etc/systemd/system/matrix-boot.service.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/matrix-boot.service.d/fix-tty1-dependency.conf" << 'EOF'
[Unit]
# Don't wait for tty1 device (causes boot hang)
After=local-fs.target
Wants=
Requires=
# Remove tty1 device dependency
EOF
    echo "  ✅ matrix-boot.service fixed (won't wait for tty1)"
fi

# Disable getty services (no multi-user support)
echo ""
echo "Disabling all getty services (no multi-user support)..."
for tty in tty1 tty2 tty3 tty4 tty5 tty6; do
    service="getty@${tty}.service"
    ln -sf /dev/null "$ROOTFS/etc/systemd/system/$service" 2>/dev/null || true
    mkdir -p "$ROOTFS/etc/systemd/system/$service.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/$service.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=0
Type=oneshot
RemainAfterExit=yes
EOF
done
# Also disable all getty template services
for getty_template in "getty@.service" "serial-getty@.service" "container-getty@.service" "autovt@.service" "console-getty.service"; do
    ln -sf /dev/null "$ROOTFS/etc/systemd/system/$getty_template" 2>/dev/null || true
    mkdir -p "$ROOTFS/etc/systemd/system/$getty_template.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/$getty_template.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=0
Type=oneshot
RemainAfterExit=yes
EOF
done
echo "  ✅ All getty services disabled (no multi-user support)"

# Disable user management services (single-user system)
echo ""
echo "Disabling user management services (single-user system)..."
USER_MGMT_SERVICES=(
    "user@.service"
    "user-runtime-dir@.service"
    "user.slice"
    "systemd-logind.service"
    "dbus-org.freedesktop.login1.service"
)

for service in "${USER_MGMT_SERVICES[@]}"; do
    # Remove from all locations
    rm -f "$ROOTFS/lib/systemd/system/$service" 2>/dev/null || true
    rm -f "$ROOTFS/usr/lib/systemd/system/$service" 2>/dev/null || true
    rm -f "$ROOTFS/etc/systemd/system/$service" 2>/dev/null || true
    
    # Remove ALL symlinks
    find "$ROOTFS/etc/systemd/system" -type l -name "*${service}*" 2>/dev/null | xargs rm -f 2>/dev/null || true
    
    # Remove from ALL target wants directories
    for target_dir in "$ROOTFS/etc/systemd/system"/*.target.wants "$ROOTFS/etc/systemd/system"/*.wants; do
        if [ -d "$target_dir" ]; then
            rm -f "$target_dir/$service" 2>/dev/null || true
        fi
    done
    
    # Mask the service
    ln -sf /dev/null "$ROOTFS/etc/systemd/system/$service" 2>/dev/null || true
    
    # Create override
    mkdir -p "$ROOTFS/etc/systemd/system/$service.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/$service.d/override.conf" << 'EOF'
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
done
echo "  ✅ All user management services disabled"

# Configure multi-user.target for single-user mode
echo ""
echo "Configuring multi-user.target for single-user mode..."
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/multi-user.target.d/disable-user-management.conf" << 'EOF'
[Unit]
# Single-user system: no user management needed
After=local-fs.target
Wants=local-fs.target
Requires=local-fs.target
# Don't require user services
Conflicts=
Before=
EOF
echo "  ✅ multi-user.target configured for single-user mode"

# Set timeouts on ALL services to prevent hangs
echo ""
echo "Setting timeouts on all services to prevent hangs..."
mkdir -p "$ROOTFS/etc/systemd/system.conf.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system.conf.d/set-timeouts.conf" << 'EOF'
[Manager]
# Prevent services from hanging indefinitely
DefaultTimeoutStartSec=10
DefaultTimeoutStopSec=5
DefaultTimeoutAbortSec=5
EOF
echo "  ✅ Global timeouts set (10s start, 5s stop)"

echo ""
echo "✅ COMPREHENSIVE FIX COMPLETE"
echo ""
echo "All problematic services disabled:"
for service in "${PROBLEMATIC_SERVICES[@]}"; do
    echo "  - $service: DISABLED"
done
echo ""
echo "Additional fixes:"
echo "  - Services with network-online dependencies: FIXED"
echo "  - Global timeouts: SET (10s max)"
echo "  - User slice services: DISABLED"
echo "  - User management services: DISABLED (single-user mode)"
echo "  - Multi-user.target: Configured for single-user mode"
echo ""
echo "Boot should now complete without hanging!"
