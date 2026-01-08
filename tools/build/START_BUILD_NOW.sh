#!/bin/bash
################################################################################
#
# START CUSTOM BUILD - GHETTOBLASTER
#
# Startet den Custom Build mit allen Fixes
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/imgbuild"

cd "$BUILD_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 STARTE CUSTOM BUILD - GHETTOBLASTER                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Build-Konfiguration:"
echo "  - Moode: 10.0.0-1moode1"
echo "  - Custom Components: ✅"
echo "  - Audio/Video Tools: ✅"
echo "  - config.txt Overwrite-Schutz: ✅"
echo ""
echo "⏱️  Geschätzte Build-Zeit: 8-12 Stunden"
echo "📁 Build-Log: imgbuild/build-*.log"
echo ""
echo "⚠️  WICHTIG: Build benötigt sudo (Passwort wird abgefragt)"
echo ""
echo "📂 Build-Verzeichnis: $BUILD_DIR"
echo "📄 Build-Script: $BUILD_DIR/build.sh"
echo ""

# Prüfe ob build.sh existiert
if [ ! -f "$BUILD_DIR/build.sh" ]; then
    echo "❌ FEHLER: build.sh nicht gefunden in $BUILD_DIR"
    echo "   Bitte prüfe, ob das Verzeichnis korrekt ist."
    exit 1
fi

echo "✅ build.sh gefunden"
echo ""
echo "🔄 Starte Build in 3 Sekunden..."
sleep 3

# Starte Build mit Log
LOG_FILE="$BUILD_DIR/build-$(date +%Y%m%d_%H%M%S).log"
echo "📝 Log-Datei: $LOG_FILE"
echo ""

# Starte Build (benötigt sudo)
# Verwende bash direkt, da sudo manchmal Probleme mit Shebang hat
sudo bash "$BUILD_DIR/build.sh" 2>&1 | tee "$LOG_FILE"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ BUILD ABGESCHLOSSEN                                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Image sollte in imgbuild/deploy/ sein"
echo ""

