#!/bin/bash
# AGGRESSIVE: Disable EVERYTHING except absolute essentials for moOde
# This matches the working 1.0 approach - minimal services only

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    exit 1
fi

echo "=== AGGRESSIVE: DISABLE ALL NON-ESSENTIAL SERVICES ==="
echo "Only keeping absolute essentials for moOde audio player"
echo ""

# ABSOLUTE ESSENTIALS ONLY (8 services)
ESSENTIAL_SERVICES=(
    "mpd.service"
    "camilladsp.service"
    "peppymeter.service"
    "localdisplay.service"
    "nginx.service"
    "php8.4-fpm.service"
    "ssh.service"
    "systemd-networkd.service"
)

# Also need basic system services
BASIC_SYSTEM=(
    "dbus.service"
    "dbus.socket"
    "systemd-logind.service"
    "wpa_supplicant.service"
)

ALL_ESSENTIAL=("${ESSENTIAL_SERVICES[@]}" "${BASIC_SYSTEM[@]}")

echo "ESSENTIAL SERVICES (will KEEP enabled):"
for service in "${ALL_ESSENTIAL[@]}"; do
    echo "  ✅ $service"
done
echo ""

# Get list of ALL enabled services
echo "Finding all enabled services..."
ENABLED_SERVICES=$(find "$ROOTFS/etc/systemd/system" -type l -name "*.service" 2>/dev/null | while read link; do
    TARGET=$(readlink "$link" 2>/dev/null || echo "")
    if [ "$TARGET" != "/dev/null" ]; then
        basename "$link"
    fi
done | sort -u)

echo "Found enabled services. Disabling all non-essential..."
echo ""

DISABLED_COUNT=0
echo "$ENABLED_SERVICES" | while read SERVICE; do
    # Skip if essential
    IS_ESSENTIAL=false
    for essential in "${ALL_ESSENTIAL[@]}"; do
        if [ "$SERVICE" = "$essential" ]; then
            IS_ESSENTIAL=true
            break
        fi
    done
    
    if [ "$IS_ESSENTIAL" = false ]; then
        # Disable this service
        echo "Disabling $SERVICE..."
        
        # Remove from all locations
        rm -f "$ROOTFS/lib/systemd/system/$SERVICE" 2>/dev/null || true
        rm -f "$ROOTFS/usr/lib/systemd/system/$SERVICE" 2>/dev/null || true
        rm -f "$ROOTFS/etc/systemd/system/$SERVICE" 2>/dev/null || true
        
        # Remove ALL symlinks
        find "$ROOTFS/etc/systemd/system" -type l -name "*${SERVICE}*" 2>/dev/null | xargs rm -f 2>/dev/null || true
        
        # Remove from target wants
        for target_dir in "$ROOTFS/etc/systemd/system"/*.target.wants "$ROOTFS/etc/systemd/system"/*.wants; do
            if [ -d "$target_dir" ] 2>/dev/null; then
                rm -f "$target_dir/$SERVICE" 2>/dev/null || true
            fi
        done
        
        # Mask the service
        mkdir -p "$ROOTFS/etc/systemd/system" 2>/dev/null || true
        ln -sf /dev/null "$ROOTFS/etc/systemd/system/$SERVICE" 2>/dev/null || true
        
        DISABLED_COUNT=$((DISABLED_COUNT + 1))
        echo "  ✅ Disabled: $SERVICE"
    else
        echo "  ✅ Keeping: $SERVICE (essential)"
    fi
done

# Ensure global timeout
echo ""
echo "Setting global timeout..."
mkdir -p "$ROOTFS/etc/systemd/system.conf.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system.conf.d/set-timeouts.conf" << 'EOF'
[Manager]
DefaultTimeoutStartSec=10
DefaultTimeoutStopSec=5
DefaultTimeoutAbortSec=5
EOF
echo "  ✅ Global timeout: 10s"

# Add timeouts to essential services
echo ""
echo "Adding timeouts to essential services..."
for SERVICE in "${ESSENTIAL_SERVICES[@]}"; do
    mkdir -p "$ROOTFS/etc/systemd/system/$SERVICE.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/$SERVICE.d/fix-timeout.conf" << 'EOF'
[Service]
TimeoutStartSec=10
TimeoutStopSec=5
EOF
done
echo "  ✅ All essential services have 10s timeout"

echo ""
echo "=== COMPLETE ==="
echo ""
echo "✅ Disabled all non-essential services"
echo "✅ Kept only 12 essential services:"
for service in "${ALL_ESSENTIAL[@]}"; do
    echo "  - $service"
done
echo ""
echo "✅ Boot should be FAST now (< 30s expected)"
echo "✅ System matches minimal 1.0 approach"
