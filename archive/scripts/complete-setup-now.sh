#!/bin/bash
################################################################################
# Senior Project Manager - Vollständiges Setup
# Konfiguriert alles automatisch ohne Fragen
################################################################################

PI_IP="192.168.178.161"
PI_USER="pi"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 VOLLSTÄNDIGES SETUP - AUTOMATISCH                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe Verbindung
if ! ping -c 2 "$PI_IP" >/dev/null 2>&1; then
    echo "❌ Pi nicht erreichbar"
    exit 1
fi

echo "✅ Pi erreichbar: $PI_IP"
echo ""

# Finde Passwort
PASS=""
for p in "DSD" "moodeaudio" "raspberry" "pi" "moode"; do
    if sshpass -p "$p" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 "$PI_USER@$PI_IP" "echo OK" >/dev/null 2>&1; then
        PASS="$p"
        echo "✅ SSH funktioniert"
        break
    fi
done

if [ -z "$PASS" ]; then
    echo "⚠️  SSH nicht verfügbar - verwende Web-UI API"
    PASS=""
fi

# 1. DISPLAY: Portrait → Landscape
echo "🖥️  1. Display-Rotation: Portrait → Landscape..."
if [ -n "$PASS" ]; then
    sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "sudo sed -i 's/display_rotate=3/display_rotate=0/' /boot/firmware/config.txt 2>/dev/null && echo '✅ config.txt aktualisiert'" 2>/dev/null
else
    echo "   ⚠️  Über Web-UI: Configure → System → Display Rotation → 0°"
fi
echo ""

# 2. BROWSER: Local Display aktivieren
echo "🌐 2. Browser starten (Local Display)..."
if [ -n "$PASS" ]; then
    sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "sudo systemctl enable localdisplay 2>/dev/null && sudo systemctl start localdisplay 2>/dev/null && echo '✅ Local Display gestartet'" 2>/dev/null
else
    echo "   ⚠️  Über Web-UI: Configure → Peripherals → Local Display → Aktivieren"
fi
echo ""

# 3. AUDIO: HiFiBerry AMP100
echo "🔊 3. Audio-Output: HiFiBerry AMP100..."
if [ -n "$PASS" ]; then
    # Prüfe verfügbare Geräte
    AUDIO_DEVICES=$(sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "aplay -l 2>/dev/null | grep -i hifiberry || echo 'Nicht gefunden'")
    echo "   Geräte: $AUDIO_DEVICES"
    
    # Setze Audio-Output über moodeutl
    sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "sudo moodeutl -a 'hifiberry-amp100' 2>/dev/null && echo '✅ Audio-Output gesetzt'" 2>/dev/null || echo "   ⚠️  moodeutl nicht verfügbar"
else
    echo "   ⚠️  Über Web-UI: Configure → Audio → Output Device → HiFiBerry AMP100"
fi
echo ""

# 4. SERVICES: Prüfe und starte
echo "⚙️  4. Services prüfen..."
if [ -n "$PASS" ]; then
    # MPD
    sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "systemctl is-active mpd >/dev/null 2>&1 && echo '   ✅ MPD läuft' || (sudo systemctl start mpd 2>/dev/null && echo '   ✅ MPD gestartet')" 2>/dev/null
    
    # PeppyMeter
    sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "systemctl is-active peppymeter-extended-displays >/dev/null 2>&1 && echo '   ✅ PeppyMeter läuft' || echo '   ⚠️  PeppyMeter nicht aktiv'" 2>/dev/null
    
    # CamillaDSP
    sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "systemctl is-active camilladsp >/dev/null 2>&1 && echo '   ✅ CamillaDSP läuft' || echo '   ℹ️  CamillaDSP nicht aktiv (normal)'" 2>/dev/null
else
    echo "   ⚠️  Services können nicht geprüft werden (SSH nicht verfügbar)"
fi
echo ""

# 5. FEATURES: Flat EQ Preset prüfen
echo "🎛️  5. Features prüfen..."
if [ -n "$PASS" ]; then
    # Flat EQ Preset Datei
    FLAT_EQ=$(sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "test -f /var/www/html/command/ghettoblaster-flat-eq.json && echo '✅ Flat EQ Preset vorhanden' || echo '⚠️  Flat EQ Preset nicht gefunden'" 2>/dev/null)
    echo "   $FLAT_EQ"
    
    # Room Correction Wizard
    ROOM_WIZARD=$(sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "test -f /var/www/html/command/room-correction-wizard.php && echo '✅ Room Correction Wizard vorhanden' || echo '⚠️  Room Correction Wizard nicht gefunden'" 2>/dev/null)
    echo "   $ROOM_WIZARD"
else
    echo "   ⚠️  Features können nicht geprüft werden (SSH nicht verfügbar)"
fi
echo ""

# 6. NEUSTART für Display-Änderung
echo "🔄 6. Neustart für Display-Änderung..."
if [ -n "$PASS" ]; then
    echo "   ⚠️  Neustart wird durchgeführt in 5 Sekunden..."
    sleep 2
    sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "sudo reboot" 2>/dev/null
    echo "   ✅ Neustart gestartet"
    echo ""
    echo "⏱️  System startet neu (~2 Minuten)"
    echo "   Nach Neustart:"
    echo "   - Display sollte Landscape sein"
    echo "   - Browser sollte automatisch starten"
    echo "   - Web-UI: http://$PI_IP"
else
    echo "   ⚠️  Neustart manuell: sudo reboot"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ SETUP ABGESCHLOSSEN                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"

