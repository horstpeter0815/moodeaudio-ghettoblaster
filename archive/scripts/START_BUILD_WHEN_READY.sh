#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🚀 BUILD STARTEN - WARTET AUF NETZWERK                      ║
# ╚══════════════════════════════════════════════════════════════╝

cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 BUILD VORBEREITUNG                                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Container läuft
if ! docker ps | grep -q moode-builder; then
    echo "📦 Starte Docker Container..."
    docker-compose -f docker-compose.build.yml up -d
    sleep 5
fi

echo "✅ Container läuft"
echo ""

# Warte auf Netzwerk
echo "🌐 Warte auf Netzwerk-Verbindung..."
MAX_WAIT=60
WAITED=0
NETWORK_READY=false

while [ $WAITED -lt $MAX_WAIT ]; do
    if docker exec moode-builder ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        NETWORK_READY=true
        echo "✅ Netzwerk verfügbar!"
        break
    fi
    echo -n "."
    sleep 2
    WAITED=$((WAITED + 2))
done

if [ "$NETWORK_READY" = false ]; then
    echo ""
    echo "⚠️  Netzwerk nicht verfügbar nach $MAX_WAIT Sekunden"
    echo "   Build wird trotzdem gestartet..."
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔥 STARTE BUILD                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 FIXES IM BUILD:"
echo "   ✅ Console deaktiviert (tty1)"
echo "   ✅ Display Landscape (0°)"
echo "   ✅ Browser startet korrekt"
echo "   ✅ Alle Services aktiviert"
echo ""
echo "⏱️  Geschätzte Dauer: 2-4 Stunden"
echo ""

# Starte Build im Container
echo "🚀 Starte Build-Prozess..."
docker exec moode-builder bash -c "cd /workspace/imgbuild && ./build.sh" 2>&1 | tee build-$(date +%Y%m%d_%H%M%S).log

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ BUILD ERFOLGREICH ABGESCHLOSSEN                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 NÄCHSTE SCHRITTE:"
    echo "   1. Image finden in: imgbuild/pi-gen-64/deploy/"
    echo "   2. Image brennen: ./BURN_IMAGE_NOW.sh"
    echo "   3. Pi booten und testen"
    echo ""
else
    echo ""
    echo "❌ BUILD FEHLGESCHLAGEN (Exit Code: $BUILD_EXIT_CODE)"
    echo "   Prüfe Log-Datei für Details"
    echo ""
fi

