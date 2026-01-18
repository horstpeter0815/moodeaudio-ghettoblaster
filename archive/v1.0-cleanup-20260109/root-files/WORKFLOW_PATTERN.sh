#!/bin/bash
# WORKFLOW_PATTERN.sh
# Feste Muster für alle Workflows
# Jeder Workflow folgt diesem Muster für Rückverfolgbarkeit

set -e

source "$(dirname "$0")/ACTION_TRACKER.sh"

# Muster: BUILD_WORKFLOW
# 1. Build-Counter verwenden
# 2. Build starten
# 3. Build überwachen
# 4. Build-Status dokumentieren

build_workflow() {
    local BUILD_NUM
    BUILD_NUM=$(bash BUILD_TRACKER.sh increment 2>&1 | grep -o "BUILD #[0-9]*" | grep -o "[0-9]*" | head -1)
    
    action_build "$BUILD_NUM" "gestartet"
    
    cd imgbuild
    nohup bash build.sh > "build-${BUILD_NUM}-$(date +%Y%m%d_%H%M%S).log" 2>&1 &
    local BUILD_PID=$!
    cd ..
    
    action_build "$BUILD_NUM" "PID: $BUILD_PID"
    echo "$BUILD_PID" > ".build-${BUILD_NUM}.pid"
    
    echo "Build #$BUILD_NUM gestartet (PID: $BUILD_PID)"
}

# Muster: VALIDATE_WORKFLOW
# 1. Suche Build-N Image explizit
# 2. Validiere es
# 3. Dokumentiere Ergebnis

validate_workflow() {
    local BUILD_NUM=$1
    
    action_validate "Build #$BUILD_NUM" "Suche Image"
    
    local IMAGE
    IMAGE=$(find imgbuild/deploy -name "*build-${BUILD_NUM}*.img" -type f 2>/dev/null | head -1)
    
    if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
        action_validate "Build #$BUILD_NUM" "FEHLGESCHLAGEN - Image nicht gefunden"
        return 1
    fi
    
    action_validate "$IMAGE" "starte Validierung"
    
    if bash VALIDATE_BUILD_IMAGE.sh >> "validate-build-${BUILD_NUM}-$(date +%Y%m%d_%H%M%S).log" 2>&1; then
        action_validate "$IMAGE" "ERFOLGREICH"
        return 0
    else
        action_validate "$IMAGE" "FEHLGESCHLAGEN"
        return 1
    fi
}

# Muster: TEST_WORKFLOW
# 1. Führe Test-Suite aus
# 2. Dokumentiere Ergebnis

test_workflow() {
    local BUILD_NUM=$1
    
    action_test "starte Test-Suite für Build #$BUILD_NUM"
    
    local TEST_LOG="test-suite-build-${BUILD_NUM}-$(date +%Y%m%d_%H%M%S).log"
    
    if timeout 600 bash complete_test_suite.sh > "$TEST_LOG" 2>&1; then
        local RESULT=$(grep -E "Tests Passed|Tests Failed" "$TEST_LOG" | tail -1)
        action_test "ERFOLGREICH: $RESULT"
        return 0
    else
        action_test "FEHLGESCHLAGEN"
        return 1
    fi
}

# Muster: BURN_WORKFLOW
# 1. Verwende NUR Build-N Image
# 2. Brenne auf SD-Karte
# 3. Dokumentiere Ergebnis

burn_workflow() {
    local BUILD_NUM=$1
    
    action_burn "Build #$BUILD_NUM" "Suche Image"
    
    local IMAGE
    IMAGE=$(find imgbuild/deploy -name "*build-${BUILD_NUM}*.img" -type f 2>/dev/null | head -1)
    
    if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
        action_burn "Build #$BUILD_NUM" "FEHLGESCHLAGEN - Image nicht gefunden"
        return 1
    fi
    
    action_burn "$IMAGE" "starte Brenn-Prozess"
    
    local BURN_LOG="burn-build-${BUILD_NUM}-$(date +%Y%m%d_%H%M%S).log"
    
    if bash BURN_IMAGE_TO_SD.sh > "$BURN_LOG" 2>&1; then
        action_burn "$IMAGE" "ERFOLGREICH"
        return 0
    else
        action_burn "$IMAGE" "FEHLGESCHLAGEN"
        return 1
    fi
}

# Muster: COMPLETE_WORKFLOW
# Führt alle Workflows in Reihenfolge aus

complete_workflow() {
    local BUILD_NUM=$1
    
    echo "=== COMPLETE WORKFLOW FÜR BUILD #$BUILD_NUM ==="
    
    # 1. Validiere
    if ! validate_workflow "$BUILD_NUM"; then
        echo "❌ Validierung fehlgeschlagen"
        return 1
    fi
    
    # 2. Test-Suite
    if ! test_workflow "$BUILD_NUM"; then
        echo "❌ Test-Suite fehlgeschlagen"
        return 1
    fi
    
    # 3. Brennen
    if ! burn_workflow "$BUILD_NUM"; then
        echo "❌ Brennen fehlgeschlagen"
        return 1
    fi
    
    echo "✅ COMPLETE WORKFLOW ERFOLGREICH FÜR BUILD #$BUILD_NUM"
    return 0
}

# Wenn als Script aufgerufen
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "$1" in
        build)
            build_workflow
            ;;
        validate)
            validate_workflow "$2"
            ;;
        test)
            test_workflow "$2"
            ;;
        burn)
            burn_workflow "$2"
            ;;
        complete)
            complete_workflow "$2"
            ;;
        *)
            echo "Usage: $0 {build|validate|test|burn|complete} [build_num]"
            exit 1
            ;;
    esac
fi

