#!/bin/bash
# Disable multi-user.target dependencies and user management

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    echo "   Mount SD card or set ROOTFS environment variable"
    exit 1
fi

echo "=== DISABLING MULTI-USER DEPENDENCIES ==="
echo "Root filesystem: $ROOTFS"
echo ""

# Find all services that depend on multi-user.target
echo "=== 1. FINDING SERVICES WITH MULTI-USER DEPENDENCIES ==="
MULTIUSER_SERVICES=$(find "$ROOTFS/lib/systemd/system" "$ROOTFS/usr/lib/systemd/system" "$ROOTFS/etc/systemd/system" -name "*.service" 2>/dev/null -exec grep -l "After=.*multi-user\|Wants=.*multi-user\|Requires=.*multi-user" {} \; | sort -u)
MULTIUSER_COUNT=$(echo "$MULTIUSER_SERVICES" | wc -l | tr -d ' ')
echo "Found $MULTIUSER_COUNT services with multi-user.target dependencies"
echo ""

# Remove multi-user dependencies from all services
echo "=== 2. REMOVING MULTI-USER DEPENDENCIES ==="
MULTIUSER_FIXED=0
find "$ROOTFS/lib/systemd/system" "$ROOTFS/usr/lib/systemd/system" "$ROOTFS/etc/systemd/system" -name "*.service" 2>/dev/null | while read service_file; do
    if grep -qE "After=.*multi-user|Wants=.*multi-user|Requires=.*multi-user" "$service_file" 2>/dev/null; then
        service_name=$(basename "$service_file")
        override_dir="$ROOTFS/etc/systemd/system/$service_name.d"
        mkdir -p "$override_dir" 2>/dev/null || true
        
        # Remove multi-user.target from After/Wants/Requires
        if [ ! -f "$override_dir/remove-multiuser-dependency.conf" ]; then
            cat > "$override_dir/remove-multiuser-dependency.conf" << 'EOF'
[Unit]
# Remove multi-user.target dependency (not needed for single-user system)
After=
Wants=
Requires=
EOF
            # If After contains multi-user, remove it but keep other dependencies
            AFTER_LINE=$(grep "^After=" "$service_file" 2>/dev/null | head -1 || echo "")
            if [ -n "$AFTER_LINE" ]; then
                # Remove multi-user.target from After line, keep others
                NEW_AFTER=$(echo "$AFTER_LINE" | sed 's/multi-user.target//g' | sed 's/  */ /g' | sed 's/^After= *$/After=/')
                if [ "$NEW_AFTER" != "$AFTER_LINE" ] && [ -n "$NEW_AFTER" ]; then
                    # Only set After if there are other dependencies
                    if [ "$NEW_AFTER" != "After=" ] && [ "$NEW_AFTER" != "After= " ]; then
                        echo "After=$NEW_AFTER" >> "$override_dir/remove-multiuser-dependency.conf" 2>/dev/null || true
                    fi
                fi
            fi
            
            MULTIUSER_FIXED=$((MULTIUSER_FIXED + 1))
            echo "  ✅ Fixed $service_name (removed multi-user dependency)"
        fi
    fi
done
echo "  ✅ Fixed $MULTIUSER_FIXED services with multi-user dependencies"
echo ""

# Disable user management services
echo "=== 3. DISABLING USER MANAGEMENT SERVICES ==="
USER_SERVICES=(
    "user@.service"
    "user-runtime-dir@.service"
    "user.slice"
    "systemd-user-sessions.service"
    "systemd-logind.service"
    "dbus-org.freedesktop.login1.service"
    "console-getty.service"
    "getty@.service"
    "serial-getty@.service"
    "container-getty@.service"
    "autovt@.service"
)

for service in "${USER_SERVICES[@]}"; do
    echo "Disabling $service..."
    
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
    
    echo "  ✅ $service disabled"
done
echo ""

# Disable services that depend on user slice
echo "=== 4. REMOVING USER SLICE DEPENDENCIES ==="
USER_SLICE_FIXED=0
find "$ROOTFS/lib/systemd/system" "$ROOTFS/usr/lib/systemd/system" "$ROOTFS/etc/systemd/system" -name "*.service" 2>/dev/null | while read service_file; do
    if grep -qE "After=.*user|Wants=.*user|Requires=.*user|user.slice|user@" "$service_file" 2>/dev/null; then
        service_name=$(basename "$service_file")
        override_dir="$ROOTFS/etc/systemd/system/$service_name.d"
        mkdir -p "$override_dir" 2>/dev/null || true
        
        # Only fix if not already fixed
        if [ ! -f "$override_dir/remove-user-slice-dependency.conf" ]; then
            cat > "$override_dir/remove-user-slice-dependency.conf" << 'EOF'
[Unit]
# Remove user slice dependencies (single-user system, no user management)
After=
Wants=
Requires=
EOF
            USER_SLICE_FIXED=$((USER_SLICE_FIXED + 1))
            echo "  ✅ Fixed $service_name (removed user slice dependency)"
        fi
    fi
done
echo "  ✅ Fixed $USER_SLICE_FIXED services with user slice dependencies"
echo ""

# Override multi-user.target to be minimal
echo "=== 5. CONFIGURING MULTI-USER.TARGET ==="
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
echo ""

# Set default.target to multi-user (but without user management)
echo "=== 6. VERIFYING DEFAULT TARGET ==="
if [ -L "$ROOTFS/etc/systemd/system/default.target" ]; then
    CURRENT_TARGET=$(readlink "$ROOTFS/etc/systemd/system/default.target" 2>/dev/null || echo "")
    echo "  Current default.target: $CURRENT_TARGET"
    # Keep it as multi-user but we've disabled user management above
    echo "  ✅ default.target will boot to multi-user (single-user mode)"
else
    echo "  ⚠️  default.target not found"
fi
echo ""

echo "=== COMPLETE ==="
echo ""
echo "✅ DISABLED:"
echo "  - Multi-user.target dependencies removed"
echo "  - All user management services disabled"
echo "  - User slice dependencies removed"
echo "  - All getty services disabled"
echo ""
echo "✅ SYSTEM NOW:"
echo "  - Single-user mode (no multi-user support)"
echo "  - No user login sessions"
echo "  - No user slice management"
echo "  - Services run as root/system"
echo ""
