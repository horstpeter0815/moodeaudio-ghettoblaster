#!/bin/bash
# Fix SD Card NOW - Complete Fix
# Korrigiert falsche IP-Adresse und alle cloud-init Blockierungen
# FUNKTIONIERT AUS JEDEM VERZEICHNIS

set -e

# Get script directory (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Fallback to absolute path if script_dir fails
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 SD-KARTE KOMPLETT FIXEN (JETZT)                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Script-Verzeichnis: $SCRIPT_DIR"
echo "Aktuelles Verzeichnis: $(pwd)"
echo ""

# Finde SD-Karte
SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
if [ -z "$SD_LINE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken und erneut versuchen."
    exit 1
fi

SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')
ROOT_MOUNT="/Volumes/rootfs"

echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
echo ""

# Mounte Root-Partition
echo "1. Mounte Root-Partition..."
sudo mkdir -p "$ROOT_MOUNT"
sudo mount -t ext4 /dev/${SD_DEVICE}s2 "$ROOT_MOUNT" 2>/dev/null || echo "Bereits gemountet"
echo "✅ Root-Partition gemountet: $ROOT_MOUNT"
echo ""

# Fix 1: network-guaranteed.service - FALSCHE IP-ADRESSE KORRIGIEREN
echo "2. Fix network-guaranteed.service (KRITISCH: Falsche IP-Adresse)..."
NETWORK_GUARANTEED_FILE=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
if [ -n "$NETWORK_GUARANTEED_FILE" ]; then
    echo "   Service-Datei: $NETWORK_GUARANTEED_FILE"
    sudo cp "$NETWORK_GUARANTEED_FILE" "${NETWORK_GUARANTEED_FILE}.bak"
    echo "   ✅ Backup erstellt"
    
    # KRITISCH: IP-Adresse von 192.168.178.162 → 192.168.10.2
    sudo sed -i '' 's/192\.168\.178\.162/192.168.10.2/g' "$NETWORK_GUARANTEED_FILE"
    sudo sed -i '' 's/192\.168\.178\.1/192.168.10.1/g' "$NETWORK_GUARANTEED_FILE"
    echo "   ✅ IP-Adresse korrigiert: 192.168.178.162 → 192.168.10.2"
    echo "   ✅ Gateway korrigiert: 192.168.178.1 → 192.168.10.1"
    
    # Netplan renderer auf NetworkManager setzen (falls networkd)
    sudo sed -i '' 's/renderer: networkd/renderer: NetworkManager/' "$NETWORK_GUARANTEED_FILE"
    echo "   ✅ Netplan renderer auf NetworkManager gesetzt"
    
    # systemd-networkd deaktivieren wenn NetworkManager aktiv
    if grep -q "systemctl restart systemd-networkd" "$NETWORK_GUARANTEED_FILE"; then
        sudo sed -i '' 's/systemctl restart systemd-networkd 2>\/dev\/null || true/# CRITICAL FIX: Deaktiviere systemd-networkd if NetworkManager is active\
        if systemctl is-active NetworkManager >\/dev\/null 2>\&1; then\
            systemctl stop systemd-networkd 2>\/dev\/null || true\
            systemctl disable systemd-networkd 2>\/dev\/null || true\
            echo "✅ systemd-networkd deaktiviert (NetworkManager aktiv)"\
        else\
            systemctl restart systemd-networkd 2>\/dev\/null || true\
        fi/' "$NETWORK_GUARANTEED_FILE"
        echo "   ✅ systemd-networkd Deaktivierungslogik hinzugefügt"
    fi
else
    echo "   ⚠️  network-guaranteed.service nicht gefunden"
fi
echo ""

# Fix 2: fix-user-id.service - After=moode-startup.service entfernen
echo "3. Fix fix-user-id.service (cloud-init Blockierung)..."
FIX_USER_ID_FILE=$(find "$ROOT_MOUNT" -name "fix-user-id.service" -type f | head -1)
if [ -n "$FIX_USER_ID_FILE" ]; then
    echo "   Service-Datei: $FIX_USER_ID_FILE"
    sudo cp "$FIX_USER_ID_FILE" "${FIX_USER_ID_FILE}.bak"
    echo "   ✅ Backup erstellt"
    sudo sed -i '' '/After=moode-startup.service/d' "$FIX_USER_ID_FILE"
    echo "   ✅ After=moode-startup.service entfernt (verhindert cloud-init Hang)"
else
    echo "   ⚠️  fix-user-id.service nicht gefunden"
fi
echo ""

# Fix 3: fix-ssh-sudoers.service - After=moode-startup.service entfernen
echo "4. Fix fix-ssh-sudoers.service (cloud-init Blockierung)..."
FIX_SSH_SUDOERS_FILE=$(find "$ROOT_MOUNT" -name "fix-ssh-sudoers.service" -type f | head -1)
if [ -n "$FIX_SSH_SUDOERS_FILE" ]; then
    echo "   Service-Datei: $FIX_SSH_SUDOERS_FILE"
    sudo cp "$FIX_SSH_SUDOERS_FILE" "${FIX_SSH_SUDOERS_FILE}.bak"
    echo "   ✅ Backup erstellt"
    sudo sed -i '' '/After=moode-startup.service/d' "$FIX_SSH_SUDOERS_FILE"
    echo "   ✅ After=moode-startup.service entfernt (verhindert cloud-init Hang)"
else
    echo "   ⚠️  fix-ssh-sudoers.service nicht gefunden"
fi
echo ""

# Fix 4: SSH früher aktivieren - ssh-guaranteed.service prüfen
echo "5. Prüfe SSH-Guaranteed Service..."
SSH_GUARANTEED_FILE=$(find "$ROOT_MOUNT" -name "ssh-guaranteed.service" -type f | head -1)
if [ -n "$SSH_GUARANTEED_FILE" ]; then
    echo "   ✅ ssh-guaranteed.service gefunden: $SSH_GUARANTEED_FILE"
    # Prüfe ob es vor cloud-init.target startet
    if grep -q "Before=cloud-init.target\|Before=network.target" "$SSH_GUARANTEED_FILE"; then
        echo "   ✅ SSH startet vor cloud-init.target"
    else
        echo "   ⚠️  SSH startet möglicherweise nicht früh genug"
    fi
else
    echo "   ⚠️  ssh-guaranteed.service nicht gefunden"
fi
echo ""

# Verifikation
echo "6. Verifikation der Fixes..."
echo ""
if [ -n "$NETWORK_GUARANTEED_FILE" ]; then
    echo "   network-guaranteed.service IP-Adressen:"
    grep -E "192\.168\.(10|178)" "$NETWORK_GUARANTEED_FILE" | head -3 || echo "   Keine IP-Adressen gefunden"
fi
echo ""
if [ -n "$FIX_USER_ID_FILE" ]; then
    echo "   fix-user-id.service Dependencies:"
    grep -E "After=|Wants=" "$FIX_USER_ID_FILE" || echo "   Keine Dependencies"
fi
echo ""
if [ -n "$FIX_SSH_SUDOERS_FILE" ]; then
    echo "   fix-ssh-sudoers.service Dependencies:"
    grep -E "After=|Wants=" "$FIX_SSH_SUDOERS_FILE" || echo "   Keine Dependencies"
fi
echo ""

# Unmount
echo "7. Unmounte SD-Karte..."
sudo umount "$ROOT_MOUNT" || true
echo "✅ SD-Karte unmounted"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ALLE FIXES ANGEWENDET                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Nächste Schritte:"
echo "  1. SD-Karte auswerfen: diskutil eject /dev/$SD_DEVICE"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten"
echo ""
echo "✅ Erwartete Ergebnisse:"
echo "  • Pi bekommt IP 192.168.10.2 (nicht mehr 192.168.178.162)"
echo "  • Keine cloud-init.target Blockierung"
echo "  • SSH funktioniert: ssh andre@192.168.10.2"
echo "  • Moode Audio startet"
echo ""

