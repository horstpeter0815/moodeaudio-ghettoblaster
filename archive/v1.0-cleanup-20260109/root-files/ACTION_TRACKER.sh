#!/bin/bash
# ACTION_TRACKER.sh
# System für Rückverfolgbarkeit und Struktur
# Jede Aktion wird mit Code, Zeitstempel und Details dokumentiert

set -e

ACTION_LOG="action-tracker-$(date +%Y%m%d).log"
ACTION_COUNTER_FILE=".action-counter"

# Lade oder initialisiere Counter
if [ -f "$ACTION_COUNTER_FILE" ]; then
    ACTION_COUNTER=$(cat "$ACTION_COUNTER_FILE")
else
    ACTION_COUNTER=0
fi

# Action Codes (feste Muster)
# BUILD: Build-Aktionen
# VALID: Validierung
# TEST: Test-Suite
# BURN: SD-Karte brennen
# DEBUG: Debugger-Aktionen
# FIX: Fehlerbehebungen

log_action() {
    local CODE=$1
    local ACTION=$2
    local DETAILS=$3
    
    ACTION_COUNTER=$((ACTION_COUNTER + 1))
    echo "$ACTION_COUNTER" > "$ACTION_COUNTER_FILE"
    
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] [$ACTION_COUNTER] [$CODE] $ACTION | $DETAILS" | tee -a "$ACTION_LOG"
}

# Funktionen für verschiedene Action-Typen
action_build() {
    local BUILD_NUM=$1
    local STATUS=$2
    log_action "BUILD" "Build #$BUILD_NUM: $STATUS" "Build-Nummer: $BUILD_NUM"
}

action_validate() {
    local IMAGE=$1
    local RESULT=$2
    log_action "VALID" "Image-Validierung: $RESULT" "Image: $(basename "$IMAGE")"
}

action_test() {
    local RESULT=$1
    log_action "TEST" "Test-Suite: $RESULT" "Tests ausgeführt"
}

action_burn() {
    local IMAGE=$1
    local RESULT=$2
    log_action "BURN" "SD-Karte brennen: $RESULT" "Image: $(basename "$IMAGE")"
}

action_debug() {
    local ACTION=$1
    local DETAILS=$2
    log_action "DEBUG" "$ACTION" "$DETAILS"
}

action_fix() {
    local PROBLEM=$1
    local SOLUTION=$2
    log_action "FIX" "Problem behoben: $PROBLEM" "Lösung: $SOLUTION"
}

# Wenn als Script aufgerufen
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "$1" in
        build)
            action_build "$2" "$3"
            ;;
        validate)
            action_validate "$2" "$3"
            ;;
        test)
            action_test "$2"
            ;;
        burn)
            action_burn "$2" "$3"
            ;;
        debug)
            action_debug "$2" "$3"
            ;;
        fix)
            action_fix "$2" "$3"
            ;;
        status)
            echo "=== ACTION TRACKER STATUS ==="
            echo "Aktueller Counter: $ACTION_COUNTER"
            echo "Log-Datei: $ACTION_LOG"
            echo ""
            echo "Letzte 10 Aktionen:"
            tail -10 "$ACTION_LOG" 2>/dev/null || echo "Keine Aktionen geloggt"
            ;;
        *)
            echo "Usage: $0 {build|validate|test|burn|debug|fix|status} [args...]"
            exit 1
            ;;
    esac
fi

