#!/bin/bash
################################################################################
#
# Script Analysis Tool
#
# Analyzes all shell scripts for syntax errors and best practices
# Uses ShellCheck if available
#
# (C) 2025 Ghettoblaster Custom Build
# License: GPLv3
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/script-analysis-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== SCRIPT ANALYSIS ===" | tee -a "$LOG_FILE"

# Check for ShellCheck
if command -v shellcheck &> /dev/null; then
    log "✅ ShellCheck gefunden"
    USE_SHELLCHECK=true
else
    log "⚠️  ShellCheck nicht gefunden (installiere mit: brew install shellcheck)"
    USE_SHELLCHECK=false
fi

# Find all shell scripts
SCRIPTS=$(find "$SCRIPT_DIR" -name "*.sh" -type f | grep -v node_modules | grep -v ".git")

log ""
log "=== ANALYSIERE SCRIPTS ==="
log "Gefundene Scripts: $(echo "$SCRIPTS" | wc -l | tr -d ' ')"

ERRORS=0
WARNINGS=0

for script in $SCRIPTS; do
    log ""
    log "Analysiere: $script"
    
    # Basic syntax check
    if bash -n "$script" 2>&1 | tee -a "$LOG_FILE"; then
        log "✅ Syntax OK"
    else
        log "❌ Syntax-Fehler gefunden"
        ERRORS=$((ERRORS + 1))
    fi
    
    # ShellCheck if available
    if [ "$USE_SHELLCHECK" = true ]; then
        if shellcheck "$script" 2>&1 | tee -a "$LOG_FILE"; then
            log "✅ ShellCheck OK"
        else
            log "⚠️  ShellCheck Warnungen"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done

log ""
log "=== ZUSAMMENFASSUNG ==="
log "Scripts analysiert: $(echo "$SCRIPTS" | wc -l | tr -d ' ')"
log "Fehler: $ERRORS"
log "Warnungen: $WARNINGS"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    log "✅ Alle Scripts OK"
    exit 0
else
    log "⚠️  Probleme gefunden - siehe Log: $LOG_FILE"
    exit 1
fi

