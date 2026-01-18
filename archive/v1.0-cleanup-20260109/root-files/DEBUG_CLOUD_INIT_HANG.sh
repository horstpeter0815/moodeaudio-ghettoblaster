#!/bin/bash
# Debug Cloud-Init Hang Script
# Analysiert warum der Pi bei cloud-init.target hängt

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 DEBUG CLOUD-INIT HANG                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Pi online ist
echo "📡 Prüfe ob Pi online ist..."
if timeout 2 ping -c 1 192.168.10.2 >/dev/null 2>&1; then
    echo "✅ Pi ist online: 192.168.10.2"
    echo ""
    echo "🔍 Analysiere Services auf dem Pi..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 andre@192.168.10.2 << 'EOF'
        echo "=== SYSTEMCTL STATUS ==="
        systemctl list-jobs | head -20
        echo ""
        echo "=== CLOUD-INIT STATUS ==="
        systemctl status cloud-init.target --no-pager | head -20
        echo ""
        echo "=== MOODE-STARTUP STATUS ==="
        systemctl status moode-startup.service --no-pager | head -20
        echo ""
        echo "=== FIX-USER-ID STATUS ==="
        systemctl status fix-user-id.service --no-pager | head -20
        echo ""
        echo "=== NETWORK STATUS ==="
        systemctl status NetworkManager --no-pager | head -20
        echo ""
        echo "=== WAITING SERVICES ==="
        systemctl list-jobs | grep -E "waiting|running" | head -10
EOF
else
    echo "⚠️  Pi ist noch nicht online"
    echo ""
    echo "📋 Analysiere SD-Karte direkt..."
    
    # Finde SD-Karte
    SD_DEVICE=$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print $NF}' 2>/dev/null)
    if [ -z "$SD_DEVICE" ]; then
        echo "❌ Keine SD-Karte gefunden!"
        echo "   Bitte SD-Karte einstecken oder Pi online schalten."
        exit 1
    fi
    
    echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
    echo ""
    
    # Mounte Root-Partition
    echo "🔌 Mounte Root-Partition..."
    sudo mkdir -p /Volumes/rootfs
    sudo mount -t ext4 /dev/${SD_DEVICE}s2 /Volumes/rootfs 2>/dev/null || echo "Root-Partition bereits gemountet"
    
    ROOT_MOUNT="/Volumes/rootfs"
    
    if [ ! -d "$ROOT_MOUNT/etc/systemd/system" ]; then
        echo "❌ Root-Partition nicht korrekt gemountet."
        exit 1
    fi
    
    echo "✅ Root-Partition: $ROOT_MOUNT"
    echo ""
    
    echo "📋 Analysiere Services auf SD-Karte..."
    echo ""
    
    echo "=== FIX-USER-ID SERVICE ==="
    FIX_USER_ID_FILE=$(find "$ROOT_MOUNT" -name "fix-user-id.service" -type f | head -1)
    if [ -n "$FIX_USER_ID_FILE" ]; then
        echo "Service-Datei: $FIX_USER_ID_FILE"
        echo ""
        grep -E "After=|Wants=|Requires=" "$FIX_USER_ID_FILE" || echo "Keine Dependencies gefunden"
    else
        echo "⚠️  fix-user-id.service nicht gefunden"
    fi
    echo ""
    
    echo "=== NETWORK-GUARANTEED SERVICE ==="
    NETWORK_GUARANTEED_FILE=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
    if [ -n "$NETWORK_GUARANTEED_FILE" ]; then
        echo "Service-Datei: $NETWORK_GUARANTEED_FILE"
        echo ""
        grep -E "After=|Wants=|Requires=" "$NETWORK_GUARANTEED_FILE" || echo "Keine Dependencies gefunden"
    else
        echo "⚠️  network-guaranteed.service nicht gefunden"
    fi
    echo ""
    
    echo "=== SERVICES MIT CLOUD-INIT DEPENDENCY ==="
    find "$ROOT_MOUNT/etc/systemd/system" -name "*.service" -type f -exec grep -l "cloud-init" {} \; 2>/dev/null | head -10
    echo ""
    
    echo "=== SERVICES MIT MOODE-STARTUP DEPENDENCY ==="
    find "$ROOT_MOUNT/etc/systemd/system" -name "*.service" -type f -exec grep -l "moode-startup" {} \; 2>/dev/null | head -10
    echo ""
    
    # Unmount
    echo "🔌 Unmounte SD-Karte..."
    sudo umount "$ROOT_MOUNT" || true
    echo "✅ Fertig"
fi

echo ""
echo "📋 Nächste Schritte:"
echo "  • Wenn fix-user-id.service auf moode-startup.service wartet:"
echo "    → Entferne After=moode-startup.service"
echo "  • Wenn NetworkManager blockiert:"
echo "    → Prüfe network-guaranteed.service"
echo "  • Wenn cloud-init selbst blockiert:"
echo "    → Prüfe cloud-init logs"
echo ""

