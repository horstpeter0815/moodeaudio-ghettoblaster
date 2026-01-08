#!/bin/bash
################################################################################
#
# START BUILD - PI 5
#
# Startet den Build für Pi 5
# Benötigt sudo-Passwort
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "═══════════════════════════════════════"
echo "  🚀 BUILD START - PI 5"
echo "═══════════════════════════════════════"
echo ""
echo "Projekt-Verzeichnis: $SCRIPT_DIR"
echo ""

# Wechsle ins Build-Verzeichnis
cd imgbuild

# Starte Build
echo "Starte Build..."
echo "⚠️  Build benötigt sudo-Passwort"
echo ""

# Build starten
bash build.sh

echo ""
echo "═══════════════════════════════════════"
echo "  ✅ BUILD GESTARTET"
echo "═══════════════════════════════════════"
echo ""
echo "Build läuft jetzt..."
echo "Prüfe Status mit: tail -f build-*.log"
echo ""

