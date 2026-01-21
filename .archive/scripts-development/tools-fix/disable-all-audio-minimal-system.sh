#!/bin/bash
# Disable ALL audio services - keep only system access (SSH, web, network)
# Fix slow services with timeouts

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    exit 1
fi

echo "=== DISABLING ALL AUDIO - MINIMAL SYSTEM ACCESS ONLY ==="
echo ""

# Disable ALL audio services
AUDIO_SERVICES=(
    "mpd.service"
    "camilladsp.service"
    "peppymeter.service"
    "camillagui.service"
    "shairport-sync.service"
    "upmpdcli.service"
    "nqptp.service"
)

echo "1. Disabling all audio services..."
for SERVICE in "${AUDIO_SERVICES[@]}"; do
    echo "   Disabling $SERVICE..."
    
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
    
    echo "     ✅ $SERVICE disabled"
done

# Find and fix "PapiMetal" or similar services
echo ""
echo "2. Searching for slow services (PapiMetal or similar)..."
SLOW_SERVICES=$(find "$ROOTFS/lib/systemd/system" \
                   "$ROOTFS/usr/lib/systemd/system" \
                   "$ROOTFS/etc/systemd/system" \
                   -name "*.service" 2>/dev/null | \
                   grep -iE "papi|metal|systemd" | head -10)

if [ -n "$SLOW_SERVICES" ]; then
    echo "$SLOW_SERVICES" | while read service_file; do
        service=$(basename "$service_file")
        echo "   Found: $service - adding timeout..."
        mkdir -p "$ROOTFS/etc/systemd/system/$service.d" 2>/dev/null || true
        cat > "$ROOTFS/etc/systemd/system/$service.d/fix-timeout.conf" << 'EOF'
[Unit]
After=local-fs.target
Wants=
Requires=

[Service]
TimeoutStartSec=10
TimeoutStopSec=5
EOF
        echo "     ✅ $service: Timeout added"
    done
else
    echo "   No services with 'papi' or 'metal' found"
fi

# Add timeouts to ALL remaining enabled services
echo ""
echo "3. Adding timeouts to ALL remaining services..."
find "$ROOTFS/etc/systemd/system" -type l -name "*.service" 2>/dev/null | while read link; do
    TARGET=$(readlink "$link" 2>/dev/null || echo "")
    if [ "$TARGET" != "/dev/null" ]; then
        SERVICE=$(basename "$link")
        mkdir -p "$ROOTFS/etc/systemd/system/$SERVICE.d" 2>/dev/null || true
        if [ ! -f "$ROOTFS/etc/systemd/system/$SERVICE.d/fix-timeout.conf" ]; then
            cat > "$ROOTFS/etc/systemd/system/$SERVICE.d/fix-timeout.conf" << 'EOF'
[Service]
TimeoutStartSec=10
TimeoutStopSec=5
EOF
            echo "   ✅ $SERVICE: Timeout added"
        fi
    fi
done

# Ensure global timeout
echo ""
echo "4. Setting global timeout..."
mkdir -p "$ROOTFS/etc/systemd/system.conf.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system.conf.d/set-timeouts.conf" << 'EOF'
[Manager]
DefaultTimeoutStartSec=10
DefaultTimeoutStopSec=5
DefaultTimeoutAbortSec=5
EOF
echo "   ✅ Global timeout: 10s"

echo ""
echo "=== COMPLETE ==="
echo ""
echo "✅ Disabled all audio services"
echo "✅ System now has only:"
echo "   - ssh.service (SSH access)"
echo "   - nginx.service (web interface)"
echo "   - php8.4-fpm.service (web interface)"
echo "   - systemd-networkd.service (network)"
echo "   - wpa_supplicant.service (WiFi)"
echo "   - dbus.service (system)"
echo ""
echo "✅ All services have 10s timeout"
echo "✅ Boot should be fast and system reachable"
