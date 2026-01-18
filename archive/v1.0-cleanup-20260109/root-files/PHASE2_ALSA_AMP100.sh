#!/bin/bash
# Phase 2.1: ALSA-Konfiguration für AMP100

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== PHASE 2.1: ALSA-KONFIGURATION (AMP100) ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'CONFIGURE_ALSA'
set -e

echo "1. Prüfe verfügbare ALSA-Geräte..."
aplay -l
echo ""

echo "2. Prüfe AMP100-Gerät..."
if aplay -l | grep -qi "amp100\|hifiberry"; then
    echo "✅ AMP100 erkannt"
    CARD=$(aplay -l | grep -i "amp100\|hifiberry" | head -1 | sed 's/card \([0-9]*\):.*/\1/')
    echo "   Card-Nummer: $CARD"
else
    echo "⚠️  AMP100 nicht erkannt"
    CARD=0
fi
echo ""

echo "3. Backup vorhandene ALSA-Config..."
[ -f /etc/asound.conf ] && sudo cp /etc/asound.conf /etc/asound.conf.backup.$(date +%Y%m%d_%H%M%S) || true
[ -f ~/.asoundrc ] && cp ~/.asoundrc ~/.asoundrc.backup.$(date +%Y%m%d_%H%M%S) || true
echo "✅ Backup erstellt"
echo ""

echo "4. Setze /etc/asound.conf (systemweit)..."
sudo tee /etc/asound.conf > /dev/null << ALSA_EOF
# HiFiBerry AMP100 ALSA Configuration
# Card: $CARD

pcm.!default {
    type hw
    card $CARD
    device 0
}

ctl.!default {
    type hw
    card $CARD
}

# AMP100 spezifische Konfiguration
pcm.amp100 {
    type hw
    card $CARD
    device 0
    format S32_LE
    rate 48000
    channels 2
}

ctl.amp100 {
    type hw
    card $CARD
}
ALSA_EOF
echo "✅ /etc/asound.conf gesetzt"
echo ""

echo "5. Setze ~/.asoundrc (user-spezifisch)..."
cat > ~/.asoundrc << ASOUNDRC_EOF
# HiFiBerry AMP100 User ALSA Configuration
pcm.!default {
    type hw
    card $CARD
    device 0
}

ctl.!default {
    type hw
    card $CARD
}
ASOUNDRC_EOF
echo "✅ ~/.asoundrc gesetzt"
echo ""

echo "6. Prüfe ALSA-Mixer..."
if command -v alsamixer &> /dev/null; then
    echo "ALSA-Mixer verfügbar"
    alsamixer -c $CARD 2>/dev/null || echo "⚠️  Mixer nicht verfügbar"
else
    echo "⚠️  alsamixer nicht installiert"
fi
echo ""

echo "7. Teste ALSA-Gerät..."
if [ -f /usr/share/sounds/alsa/Front_Left.wav ]; then
    echo "Teste mit Test-Ton..."
    timeout 2 aplay -D hw:$CARD,0 /usr/share/sounds/alsa/Front_Left.wav 2>&1 && echo "✅ Audio-Test erfolgreich" || echo "⚠️  Audio-Test fehlgeschlagen"
else
    echo "⚠️  Test-Ton nicht verfügbar"
fi
echo ""

echo "8. Prüfe Sample-Rate-Unterstützung..."
for rate in 44100 48000 88200 96000; do
    if aplay -D hw:$CARD,0 --dump-hw-params -r $rate /dev/zero 2>&1 | grep -q "rate $rate"; then
        echo "   ✅ $rate Hz unterstützt"
    else
        echo "   ⚠️  $rate Hz nicht unterstützt"
    fi
done
echo ""

echo "=== ALSA-KONFIGURATION ABGESCHLOSSEN ==="
echo ""
echo "✅ ALSA konfiguriert für Card $CARD (AMP100)"
echo ""
echo "Nächste Schritte:"
echo "  - Phase 2.2: PulseAudio Setup (optional)"
echo "  - Phase 2.3: MPD Audio-Konfiguration"
echo "  - Phase 2.4: Audio-Test"
echo ""
CONFIGURE_ALSA

echo ""
echo "=== FERTIG ==="
echo ""

