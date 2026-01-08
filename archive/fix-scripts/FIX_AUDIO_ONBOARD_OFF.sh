#!/bin/bash
# Fix Audio Configuration - Deactivate Onboard Sound, Ensure AMP100
# Usage: sudo /Users/andrevollmer/moodeaudio-cursor/FIX_AUDIO_ONBOARD_OFF.sh [PI_IP]

set -e

PI_IP="${1:-192.168.1.130}"
PI_USER="andre"
PI_PASS="0815"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX AUDIO: DEAKTIVIERE ONBOARD SOUND, AKTIVIERE AMP100   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "Pi IP: $PI_IP"
echo ""

# Warte auf Pi
echo "Warte auf Pi..."
for i in {1..30}; do
    if ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
        echo "✅ Pi ist online!"
        break
    fi
    echo "Versuch $i/30..."
    sleep 2
done

if ! ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
    echo "❌ Pi nicht erreichbar: $PI_IP"
    exit 1
fi

echo ""
echo "=== FIX AUDIO KONFIGURATION ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'SSH_EOF'
set -e

echo "1. Backup config.txt..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup_audio_$(date +%Y%m%d_%H%M%S)

echo "2. Prüfe aktuelle Audio-Konfiguration..."
echo ""
echo "Aktuelle [pi5] Section:"
grep -A 5 '^\[pi5\]' /boot/firmware/config.txt || echo "Keine [pi5] Section gefunden"

echo ""
echo "Aktuelle Audio Settings:"
grep -E 'dtoverlay.*vc4|dtparam.*audio|noaudio' /boot/firmware/config.txt || echo "Keine Audio Settings gefunden"

echo ""
echo "3. Deaktiviere Onboard Sound..."

# Stelle sicher dass [pi5] Section existiert
if ! grep -q '^\[pi5\]' /boot/firmware/config.txt; then
    echo "Erstelle [pi5] Section..."
    sudo sed -i '/^\[all\]/i [pi5]\n# Pi 5 specific settings\n' /boot/firmware/config.txt
fi

# Setze noaudio in vc4-kms-v3d-pi5 overlay
sudo sed -i '/^\[pi5\]/,/^\[/ {
    /dtoverlay=vc4-kms-v3d-pi5/ {
        s/,noaudio//g
        s/$/,noaudio/
        s/,noaudio,noaudio/,noaudio/
    }
}' /boot/firmware/config.txt

# Falls vc4-kms-v3d-pi5 ohne noaudio existiert, füge es hinzu
if grep -q '^\[pi5\]' /boot/firmware/config.txt && ! grep -q 'dtoverlay=vc4-kms-v3d-pi5,noaudio' /boot/firmware/config.txt; then
    if grep -q 'dtoverlay=vc4-kms-v3d-pi5' /boot/firmware/config.txt; then
        sudo sed -i '/dtoverlay=vc4-kms-v3d-pi5/ s/$/,noaudio/' /boot/firmware/config.txt
    else
        sudo sed -i '/^\[pi5\]/a dtoverlay=vc4-kms-v3d-pi5,noaudio' /boot/firmware/config.txt
    fi
fi

# Setze dtparam=audio=off in [all] Section
if ! grep -q '^dtparam=audio=off' /boot/firmware/config.txt; then
    if grep -q '^dtparam=audio=on' /boot/firmware/config.txt; then
        sudo sed -i 's/^dtparam=audio=on/dtparam=audio=off/' /boot/firmware/config.txt
    else
        sudo sed -i '/^\[all\]/a dtparam=audio=off' /boot/firmware/config.txt
    fi
fi

echo "✅ Onboard Sound deaktiviert"

echo ""
echo "4. Prüfe AMP100 dtoverlay..."
if grep -q 'dtoverlay=hifiberry-amp100' /boot/firmware/config.txt; then
    echo "✅ AMP100 dtoverlay vorhanden"
else
    echo "⚠️  AMP100 dtoverlay fehlt - füge hinzu..."
    sudo sed -i '/^\[all\]/a dtoverlay=hifiberry-amp100,automute' /boot/firmware/config.txt
    echo "✅ AMP100 dtoverlay hinzugefügt"
fi

echo ""
echo "5. Prüfe I2S..."
if grep -q '^dtparam=i2s=on' /boot/firmware/config.txt; then
    echo "✅ I2S aktiviert"
else
    echo "⚠️  I2S fehlt - füge hinzu..."
    sudo sed -i '/^\[all\]/a dtparam=i2s=on' /boot/firmware/config.txt
    echo "✅ I2S hinzugefügt"
fi

echo ""
echo "6. Finale Prüfung..."
echo ""
echo "[pi5] Section:"
grep -A 5 '^\[pi5\]' /boot/firmware/config.txt | head -6

echo ""
echo "Audio Settings:"
grep -E 'dtoverlay.*vc4|dtparam.*audio|dtoverlay.*hifiberry|dtparam.*i2s' /boot/firmware/config.txt

echo ""
echo "=== KONFIGURATION ABGESCHLOSSEN ==="
echo ""
echo "✅ Onboard Sound: DEAKTIVIERT (noaudio + dtparam=audio=off)"
echo "✅ AMP100: AKTIVIERT (dtoverlay=hifiberry-amp100,automute)"
echo "✅ I2S: AKTIVIERT (dtparam=i2s=on)"
echo ""
echo "⚠️  REBOOT ERFORDERLICH!"
echo "   Nach Reboot sollte nur AMP100 als Audio-Device verfügbar sein"
SSH_EOF

echo ""
echo "=== FIX ABGESCHLOSSEN ==="
echo ""
echo "✅ Onboard Sound deaktiviert"
echo "✅ AMP100 konfiguriert"
echo ""
echo "⚠️  REBOOT ERFORDERLICH!"
echo "   Bitte Pi neu starten: ssh $PI_USER@$PI_IP 'sudo reboot'"
echo ""

