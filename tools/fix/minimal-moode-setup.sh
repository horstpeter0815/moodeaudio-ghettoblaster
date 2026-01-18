#!/bin/bash
# MINIMAL MOODE SETUP - Disable everything except essential audio services
# This is the "disable approach" - faster boot, fewer services

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    exit 1
fi

echo "=== MINIMAL MOODE SETUP ==="
echo "Disabling non-essential services for fast boot"
echo ""

# ESSENTIAL SERVICES (keep enabled - these are needed for moOde)
ESSENTIAL_SERVICES=(
    "mpd.service"
    "camilladsp.service"
    "peppymeter.service"
    "localdisplay.service"
    "nginx.service"
    "php8.4-fpm.service"
    "ssh.service"
    "systemd-networkd.service"
    "wpa_supplicant.service"
)

# SERVICES TO DISABLE (not needed for basic audio playback)
SERVICES_TO_DISABLE=(
    # Network waiting (slow)
    "NetworkManager-wait-online.service"
    "systemd-networkd-wait-online.service"
    "network-online.target"
    
    # System stats (slow)
    "systemd-statcollect.service"
    
    # Time/date (if not critical)
    "systemd-timedated.service"
    
    # Automatic updates (not needed)
    "apt-daily.service"
    "apt-daily-upgrade.service"
    
    # Network services (if not using)
    "avahi-daemon.service"
    "nmbd.service"
    "smbd.service"
    "winbind.service"
    "samba.service"
    "samba-ad-dc.service"
    
    # Logging (if not needed)
    "log2ram.service"
    "rsyslog.service"
    
    # Other slow services
    "ModemManager.service"
    "rpcbind.service"
    "nfs-server.service"
)

echo "Disabling non-essential services..."
DISABLED_COUNT=0
for SERVICE in "${SERVICES_TO_DISABLE[@]}"; do
    # Check if service exists
    SERVICE_EXISTS=false
    for f in "$ROOTFS/lib/systemd/system/$SERVICE" \
             "$ROOTFS/usr/lib/systemd/system/$SERVICE" \
             "$ROOTFS/etc/systemd/system/$SERVICE"; do
        if [ -f "$f" ] || [ -L "$f" ]; then
            SERVICE_EXISTS=true
            break
        fi
    done
    
    if [ "$SERVICE_EXISTS" = true ]; then
        # Remove from all locations
        rm -f "$ROOTFS/lib/systemd/system/$SERVICE" 2>/dev/null || true
        rm -f "$ROOTFS/usr/lib/systemd/system/$SERVICE" 2>/dev/null || true
        rm -f "$ROOTFS/etc/systemd/system/$SERVICE" 2>/dev/null || true
        
        # Remove from target wants
        find "$ROOTFS/etc/systemd/system" -type l -name "*${SERVICE}*" 2>/dev/null | xargs rm -f 2>/dev/null || true
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
    fi
done

echo ""
echo "=== SUMMARY ==="
echo ""
echo "✅ Disabled: $DISABLED_COUNT non-essential services"
echo ""
echo "✅ KEPT ENABLED (essential for moOde):"
for SERVICE in "${ESSENTIAL_SERVICES[@]}"; do
    echo "  - $SERVICE"
done
echo ""
echo "✅ Result:"
echo "  - Minimal moOde setup"
echo "  - Only essential audio services enabled"
echo "  - Fast boot expected (< 30s)"
echo ""
echo "Boot should be MUCH faster now!"
