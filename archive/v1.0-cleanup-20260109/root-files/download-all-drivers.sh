#!/bin/bash
# 🔧 DOWNLOAD ALL DRIVER REPOSITORIES
# Lädt alle Treiber-Repositories herunter für proaktive Analyse

set -e

DRIVERS_DIR="drivers-repos"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 DOWNLOAD ALL DRIVER REPOSITORIES                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Erstelle Drivers-Verzeichnis
mkdir -p "$DRIVERS_DIR"
cd "$DRIVERS_DIR"

# Alle Treiber-Repositories
DRIVERS=(
    # Raspberry Pi Kernel (für Device Tree Overlays)
    "raspberrypi-linux|https://github.com/raspberrypi/linux.git"
    
    # Waveshare Display Treiber
    "waveshare-dsi-lcd|https://github.com/waveshare/LCD-show.git"
    "waveshare-drivers|https://github.com/waveshare/Waveshare-DSI-LCD.git"
    
    # FT6236 Touchscreen
    "ft6236-driver|https://github.com/raspberrypi/linux.git|arch/arm/boot/dts/overlays/ft6236-overlay.dts"
    
    # HiFiBerry Treiber
    "hifiberry-drivers|https://github.com/hifiberry/hifiberry-dac.git"
    "hifiberry-amp100|https://github.com/hifiberry/hifiberry-amp.git"
    
    # ALSA / Audio Treiber
    "alsa-driver|https://github.com/alsa-project/alsa-driver.git"
    "alsa-lib|https://github.com/alsa-project/alsa-lib.git"
    
    # I2C / SPI Treiber
    "i2c-tools|https://github.com/groeck/i2c-tools.git"
    
    # Device Tree Compiler
    "device-tree-compiler|https://github.com/dgibson/dtc.git"
)

echo "📥 Lade Treiber-Repositories herunter (Shallow Clone)..."
echo ""

DOWNLOADED=0
SKIPPED=0
FAILED=0

for driver_entry in "${DRIVERS[@]}"; do
    IFS='|' read -r name url extra <<< "$driver_entry"
    
    echo -n "🔧 $name... "
    
    if [ -d "$name" ]; then
        echo -e "${YELLOW}bereits vorhanden${NC}"
        ((SKIPPED++))
    else
        if git clone --depth 1 "$url" "$name" 2>/dev/null; then
            echo -e "${GREEN}✅${NC}"
            ((DOWNLOADED++))
        else
            echo -e "${YELLOW}❌ Fehler${NC}"
            ((FAILED++))
        fi
    fi
done

# Spezielle Downloads
echo ""
echo "📥 Lade spezielle Treiber-Komponenten..."

# Waveshare DSI LCD spezifisch
if [ ! -d "waveshare-dsi-lcd-1280x400" ]; then
    echo -n "🔧 Waveshare DSI LCD 1280x400... "
    # Versuche verschiedene mögliche Repositories
    if git clone --depth 1 "https://github.com/waveshare/Waveshare-DSI-LCD-5.15.61-Pi4-32.git" "waveshare-dsi-lcd-1280x400" 2>/dev/null; then
        echo -e "${GREEN}✅${NC}"
        ((DOWNLOADED++))
    else
        echo -e "${YELLOW}⚠️  Nicht gefunden (möglicherweise lokal vorhanden)${NC}"
    fi
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ DOWNLOAD ABGESCHLOSSEN                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  ✅ Heruntergeladen: $DOWNLOADED"
echo "  ⏭️  Übersprungen: $SKIPPED"
echo "  ❌ Fehler: $FAILED"
echo ""

# Größe anzeigen
if [ $DOWNLOADED -gt 0 ] || [ $SKIPPED -gt 0 ]; then
    TOTAL_SIZE=$(du -sh . 2>/dev/null | cut -f1)
    echo "  💾 Gesamtgröße: $TOTAL_SIZE"
    echo ""
    echo "📁 Repositories in: $(pwd)"
fi

echo ""
echo "🎯 Nächste Schritte:"
echo "  - Device Tree Overlays analysieren"
echo "  - Display-Treiber-Probleme verstehen"
echo "  - Audio-Treiber-Integration prüfen"
echo "  - Proaktive Lösungen entwickeln"

