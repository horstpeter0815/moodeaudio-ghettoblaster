#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🔍 BUILD STATUS CHECKER                                     ║
# ╚══════════════════════════════════════════════════════════════╝

cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📊 BUILD STATUS                                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Build-Prozess läuft
BUILD_PID=$(ps aux | grep "START_BUILD_WHEN_READY.sh" | grep -v grep | awk '{print $2}')
if [ -n "$BUILD_PID" ]; then
    echo "✅ Build-Prozess läuft (PID: $BUILD_PID)"
else
    echo "⚠️  Kein Build-Prozess gefunden"
fi

# Prüfe Docker Container
if docker ps | grep -q moode-builder; then
    echo "✅ Docker Container läuft"
    
    # Prüfe ob Build im Container läuft
    if docker exec moode-builder ps aux | grep -q "build.sh"; then
        echo "✅ Build läuft im Container"
    else
        echo "⚠️  Kein Build-Prozess im Container"
    fi
else
    echo "❌ Docker Container nicht gefunden"
fi

echo ""

# Zeige letzte Log-Zeilen
LATEST_LOG=$(ls -t build-autonomous-*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
    echo "📋 Letzte Log-Zeilen aus: $LATEST_LOG"
    echo "────────────────────────────────────────────────────────────"
    tail -10 "$LATEST_LOG" 2>/dev/null | sed 's/^/   /'
    echo ""
else
    echo "⚠️  Keine Log-Datei gefunden"
fi

# Prüfe ob Image fertig ist
if [ -f "imgbuild/pi-gen-64/deploy/"*.img ] 2>/dev/null; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ BUILD ABGESCHLOSSEN - IMAGE GEFUNDEN!                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    ls -lh imgbuild/pi-gen-64/deploy/*.img 2>/dev/null
    echo ""
    echo "📋 Nächster Schritt: ./BURN_IMAGE_NOW.sh"
elif docker exec moode-builder test -f /workspace/imgbuild/pi-gen-64/deploy/*.img 2>/dev/null; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ BUILD ABGESCHLOSSEN - IMAGE IM CONTAINER!                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    docker exec moode-builder ls -lh /workspace/imgbuild/pi-gen-64/deploy/*.img 2>/dev/null
    echo ""
    echo "📋 Nächster Schritt: Image kopieren und brennen"
else
    echo "⏳ Build läuft noch..."
fi

echo ""

