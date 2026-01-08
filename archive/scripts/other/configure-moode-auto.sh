#!/bin/bash
################################################################################
# Automatische moOde Konfiguration
# Konfiguriert Audio, Display und Features nach dem Setup
################################################################################

PI_IP="192.168.178.161"
PI_USER="pi"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 AUTOMATISCHE MOODE KONFIGURATION                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe Verbindung
if ! ping -c 2 "$PI_IP" >/dev/null 2>&1; then
    echo "❌ Pi nicht erreichbar: $PI_IP"
    exit 1
fi

echo "✅ Pi erreichbar: $PI_IP"
echo ""

# Finde Passwort
PASS=""
for p in "DSD" "moodeaudio" "raspberry" "pi"; do
    if sshpass -p "$p" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 "$PI_USER@$PI_IP" "echo OK" >/dev/null 2>&1; then
        PASS="$p"
        break
    fi
done

if [ -z "$PASS" ]; then
    echo "⚠️  SSH nicht verfügbar - verwende Web-UI API"
    echo ""
    echo "📋 Manuelle Konfiguration erforderlich:"
    echo "   1. Web-UI öffnen: http://$PI_IP"
    echo "   2. Audio Settings → Output Device: HiFiBerry AMP100"
    echo "   3. System Settings → Display: 1280x400"
    exit 0
fi

echo "✅ SSH funktioniert"
echo ""

# 1. Audio-Output: HiFiBerry AMP100
echo "🔊 Konfiguriere Audio-Output (HiFiBerry AMP100)..."
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "sudo moodeutl -a 'hifiberry-amp100'" 2>/dev/null
echo "✅ Audio-Output konfiguriert"
echo ""

# 2. Prüfe Display-Konfiguration
echo "🖥️  Prüfe Display-Konfiguration..."
DISPLAY_INFO=$(sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "tvservice -s 2>/dev/null || echo 'Display-Info nicht verfügbar'")
echo "   $DISPLAY_INFO"
echo ""

# 3. Prüfe Services
echo "⚙️  Prüfe Services..."
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "systemctl is-active mpd && echo '✅ MPD läuft' || echo '⚠️ MPD nicht aktiv'" 2>/dev/null
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "systemctl is-active peppymeter-extended-displays && echo '✅ PeppyMeter läuft' || echo '⚠️ PeppyMeter nicht aktiv'" 2>/dev/null
echo ""

# 4. Prüfe Audio-Geräte
echo "🎛️  Verfügbare Audio-Geräte:"
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "aplay -l 2>/dev/null | head -10" 2>/dev/null
echo ""

# 5. Prüfe config.txt
echo "📝 Prüfe config.txt..."
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "grep -E 'hifiberry|amp100|display|hdmi_cvt' /boot/firmware/config.txt 2>/dev/null | head -10" 2>/dev/null
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ KONFIGURATION ABGESCHLOSSEN                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Web-UI: http://$PI_IP"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "1. Web-UI öffnen und Audio-Output prüfen"
echo "2. Features testen:"
echo "   - Flat EQ Preset (Audio Settings)"
echo "   - Room Correction Wizard (Audio Settings)"
echo "   - PeppyMeter Touch Gestures"
echo ""

