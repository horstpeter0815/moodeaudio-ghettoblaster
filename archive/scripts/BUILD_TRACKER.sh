#!/bin/bash
################################################################################
#
# BUILD TRACKER
# 
# Nummeriert jeden Build und trackt den Fortschritt
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

COUNTER_FILE="$SCRIPT_DIR/BUILD_COUNTER.txt"
LOG_FILE="$SCRIPT_DIR/BUILD_HISTORY.log"

# Lese aktuellen Counter
if [ -f "$COUNTER_FILE" ]; then
    CURRENT=$(cat "$COUNTER_FILE")
else
    CURRENT=0
fi

# Erhöhe Counter
NEXT=$((CURRENT + 1))
echo "$NEXT" > "$COUNTER_FILE"

# Logge Build-Start
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build #$NEXT gestartet" >> "$LOG_FILE"

echo "═══════════════════════════════════════"
echo "  🔢 BUILD #$NEXT"
echo "═══════════════════════════════════════"
echo ""
echo "Vorherige Builds: $CURRENT"
echo "Aktueller Build: #$NEXT"
echo ""
echo "Starte Build mit Nummerierung..."

# Erstelle Build-Verzeichnis mit Nummer
BUILD_DIR="$SCRIPT_DIR/imgbuild/deploy"
mkdir -p "$BUILD_DIR"

# Starte Build mit Nummer im Namen
cd "$SCRIPT_DIR/imgbuild"
BUILD_LOG="$BUILD_DIR/build-$NEXT-$(date +%Y%m%d_%H%M%S).log"

echo "📋 Build-Log: $BUILD_LOG"
echo ""

# Starte Build
bash build.sh 2>&1 | tee "$BUILD_LOG" &

BUILD_PID=$!
echo "✅ Build #$NEXT gestartet (PID: $BUILD_PID)"
echo ""

# Warte auf Build-Ende und benenne Image um
wait $BUILD_PID
BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
    # Finde neuestes Image
    LATEST_IMAGE=$(find "$BUILD_DIR" -name "*.img" -type f -exec ls -t {} + | head -1)
    
    if [ -n "$LATEST_IMAGE" ]; then
        # Benenne Image um mit Build-Nummer
        IMAGE_NAME="moode-r1001-arm64-build-$NEXT-$(date +%Y%m%d_%H%M%S).img"
        NEW_IMAGE="$BUILD_DIR/$IMAGE_NAME"
        mv "$LATEST_IMAGE" "$NEW_IMAGE" 2>/dev/null || cp "$LATEST_IMAGE" "$NEW_IMAGE"
        
        echo "✅ Build #$NEXT erfolgreich!"
        echo "📦 Image: $IMAGE_NAME"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build #$NEXT erfolgreich: $IMAGE_NAME" >> "$LOG_FILE"
    else
        echo "⚠️  Build #$NEXT abgeschlossen, aber kein Image gefunden"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build #$NEXT fehlgeschlagen: Kein Image" >> "$LOG_FILE"
    fi
else
    echo "❌ Build #$NEXT fehlgeschlagen (Exit: $BUILD_EXIT)"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build #$NEXT fehlgeschlagen (Exit: $BUILD_EXIT)" >> "$LOG_FILE"
fi

echo ""
echo "═══════════════════════════════════════"
echo "  📊 BUILD #$NEXT ABGESCHLOSSEN"
echo "═══════════════════════════════════════"

