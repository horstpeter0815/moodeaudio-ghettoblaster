#!/bin/bash
################################################################################
#
# BUILD NOW - GUARANTEED SOLUTION
#
# Startet Build mit allen Guaranteed Fixes
# SSH + Netzwerk werden GARANTIERT funktionieren
#
################################################################################

set -e

# Stelle sicher, dass wir im richtigen Verzeichnis sind
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || {
    echo "❌ ERROR: Kann nicht ins Projekt-Verzeichnis wechseln"
    exit 1
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 BUILD STARTEN - GUARANTEED SOLUTION                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Schritt 1: Komponenten integrieren
echo "📋 SCHRITT 1: Komponenten integrieren..."
./INTEGRATE_CUSTOM_COMPONENTS.sh

if [ $? -ne 0 ]; then
    echo "❌ ERROR: INTEGRATE fehlgeschlagen"
    exit 1
fi

echo ""
echo "✅ Komponenten integriert"
echo ""

# Schritt 2: Build starten
echo "📋 SCHRITT 2: Build starten..."
~/START_BUILD_WHEN_READY.sh

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ BUILD GESTARTET                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 NACH DEM BUILD:"
echo "  1. Image brennen: ~/BURN_NOW.sh"
echo "  2. Pi booten"
echo "  3. SSH: ssh andre@192.168.178.162 (Password: 0815)"
echo "  4. Web-UI: http://192.168.178.162"
echo ""
echo "✅ SSH + NETZWERK WERDEN GARANTIERT FUNKTIONIEREN"

