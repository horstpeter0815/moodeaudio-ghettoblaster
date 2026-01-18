#!/bin/bash
# HIFIBERRYOS HERUNTERFAHREN UND MOODE AUDIO VORBEREITEN

echo "=== HIFIBERRYOS → MOODE AUDIO ==="
echo ""

# Prüfe ob HiFiBerryOS Pi online ist
HIFIBERRY_IP="192.168.178.XXX"  # TODO: IP-Adresse eintragen
HIFIBERRY_USER="root"
HIFIBERRY_PASS="hifiberry"

echo "1. Prüfe HiFiBerryOS Status:"
echo "   IP: $HIFIBERRY_IP"
echo "   User: $HIFIBERRY_USER"
echo ""

# Versuche Verbindung
if sshpass -p "$HIFIBERRY_PASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$HIFIBERRY_USER@$HIFIBERRY_IP" "echo 'HiFiBerryOS online'" 2>/dev/null; then
    echo "   ✅ HiFiBerryOS ist online"
    echo ""
    
    echo "2. Herunterfahren HiFiBerryOS:"
    sshpass -p "$HIFIBERRY_PASS" ssh -o StrictHostKeyChecking=no "$HIFIBERRY_USER@$HIFIBERRY_IP" << 'SHUTDOWN'
        echo "   Fahre System herunter..."
        sudo shutdown -h now
SHUTDOWN
    echo "   ✅ HiFiBerryOS wird heruntergefahren"
    echo ""
    
    echo "3. Warte auf Shutdown..."
    sleep 10
    echo ""
    
    echo "4. Nächste Schritte:"
    echo "   - SD-Karte aus HiFiBerryOS Pi entfernen"
    echo "   - Moode Audio Image auf SD-Karte schreiben"
    echo "   - SD-Karte in Pi einstecken"
    echo "   - Moode Audio konfigurieren"
    echo ""
else
    echo "   ⚠️  HiFiBerryOS nicht erreichbar oder bereits offline"
    echo ""
    echo "   Nächste Schritte:"
    echo "   1. SD-Karte aus HiFiBerryOS Pi entfernen"
    echo "   2. Moode Audio Image auf SD-Karte schreiben"
    echo "   3. SD-Karte in Pi einstecken"
    echo "   4. Moode Audio konfigurieren"
    echo ""
fi

echo "✅ HiFiBerryOS → Moode Audio Vorbereitung abgeschlossen"

