#!/bin/bash
################################################################################
#
# BUILD ATTEMPT TRACKER
#
# Zeigt Versuch-Nummer bei jedem Build-Start
#
################################################################################

COUNTER_FILE="BUILD_COUNTER.txt"

# Lese aktuellen Counter oder setze auf Basis aller Builds
if [ -f "$COUNTER_FILE" ]; then
    CURRENT_COUNT=$(cat "$COUNTER_FILE")
else
    # Zähle alle bisherigen Builds
    DEPLOY_IMAGES=$(ls -1 ./imgbuild/deploy/*.img 2>/dev/null | wc -l | tr -d ' ')
    CONTAINER_IMAGES=$(docker exec moode-builder bash -c "find /tmp/pi-gen-work -name '*.img' -size +100M 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
    BUILD_LOGS=$(docker exec moode-builder bash -c "ls -1 /workspace/build-*.log 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
    CURRENT_COUNT=$((DEPLOY_IMAGES + CONTAINER_IMAGES + BUILD_LOGS))
    # Setze auf mindestens 15 (basierend auf User-Schätzung)
    if [ "$CURRENT_COUNT" -lt 15 ]; then
        CURRENT_COUNT=15
    fi
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

export BUILD_ATTEMPT_NUMBER=$NEXT_COUNT
echo "$NEXT_COUNT"

