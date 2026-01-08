#!/bin/bash
################################################################################
#
# START BUILD WITH NUMBER
#
# Startet Build und zeigt Versuch-Nummer
#
################################################################################

cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

# Lese Counter
COUNTER_FILE="BUILD_COUNTER.txt"
if [ -f "$COUNTER_FILE" ]; then
    CURRENT_COUNT=$(cat "$COUNTER_FILE")
else
    CURRENT_COUNT=25  # Basierend auf bisherigen Builds
fi

# Erhöhe für neuen Versuch
NEXT_COUNT=$((CURRENT_COUNT + 1))
echo "$NEXT_COUNT" > "$COUNTER_FILE"

# Zeige Versuch-Nummer
echo "═══════════════════════════════════════════════════════════"
echo "🚀 VERSUCH #$NEXT_COUNT - BUILD STARTET"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📊 Bisherige Versuche: $CURRENT_COUNT"
echo "📊 Aktueller Versuch: #$NEXT_COUNT"
echo ""

# Integriere Komponenten
./INTEGRATE_CUSTOM_COMPONENTS.sh > /dev/null 2>&1

# Starte Build
docker exec moode-builder bash -c "cd /workspace/imgbuild && rm -rf /tmp/pi-gen-work/moode-r1001-arm64/stage3/03-ghettoblaster-custom 2>/dev/null || true"
docker exec -d moode-builder bash -c "cd /workspace/imgbuild && WORK_DIR=/tmp/pi-gen-work nohup bash -c './build.sh 2>&1 | tee /workspace/build-attempt-$NEXT_COUNT-$(date +%Y%m%d_%H%M%S).log' > /dev/null 2>&1 &"

sleep 10

BUILD_PID=$(docker exec moode-builder pgrep -f "build.sh" 2>/dev/null | head -1)
if [ -n "$BUILD_PID" ]; then
    echo "✅ BUILD GESTARTET (PID: $BUILD_PID)"
    echo "$(date +%Y-%m-%d\ %H:%M:%S) ✅ VERSUCH #$NEXT_COUNT gestartet (PID: $BUILD_PID)" >> BUILD_STATUS_AUTONOMOUS.txt
else
    echo "❌ Build konnte nicht gestartet werden"
    exit 1
fi

