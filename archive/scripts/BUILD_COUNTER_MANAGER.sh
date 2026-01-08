#!/bin/bash
################################################################################
#
# BUILD COUNTER MANAGER
#
# Nummeriert jeden Build-Versuch und zeigt die Nummer
#
################################################################################

COUNTER_FILE="BUILD_COUNTER.txt"

# Lese aktuellen Counter
if [ -f "$COUNTER_FILE" ]; then
    CURRENT_COUNT=$(cat "$COUNTER_FILE")
else
    CURRENT_COUNT=0
fi

# Erhöhe Counter
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

# Exportiere für andere Scripts
export BUILD_ATTEMPT_NUMBER=$NEXT_COUNT
echo "$NEXT_COUNT"

