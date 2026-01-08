#!/bin/bash
# test_debugger.sh
# Test-Suite für Debugger-Integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SERIAL_PORT="${SERIAL_PORT:-/dev/cu.usbmodem214302}"
BAUDRATE="${BAUDRATE:-115200}"
LOG_DIR="debugger-test-logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/debugger-test-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

test_pass() {
    log "✅ $1"
}

test_fail() {
    log "❌ $1"
    exit 1
}

test_warn() {
    log "⚠️  $1"
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 DEBUGGER TEST SUITE                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "=== DEBUGGER TEST SUITE START ==="

# Test 1: Serial Port Availability
echo ""
echo "📋 TEST 1: SERIAL PORT AVAILABILITY"
echo "────────────────────────────────────────────────────────────────"

if [ -e "$SERIAL_PORT" ]; then
    test_pass "Serial Port $SERIAL_PORT gefunden"
else
    test_warn "Serial Port $SERIAL_PORT nicht gefunden"
    echo "   → Möglicherweise nicht verbunden oder anderer Port"
    echo "   → Prüfe verfügbare Ports:"
    ls -1 /dev/cu.* 2>/dev/null | head -5 || echo "   → Keine Ports gefunden"
fi

# Test 2: Serial Console Tools
echo ""
echo "📋 TEST 2: SERIAL CONSOLE TOOLS"
echo "────────────────────────────────────────────────────────────────"

if command -v cu >/dev/null 2>&1; then
    test_pass "cu verfügbar"
    CU_VERSION=$(cu --version 2>&1 | head -1 || echo "unknown")
    log "   Version: $CU_VERSION"
else
    test_warn "cu nicht verfügbar"
fi

if command -v screen >/dev/null 2>&1; then
    test_pass "screen verfügbar"
    SCREEN_VERSION=$(screen --version 2>&1 | head -1 || echo "unknown")
    log "   Version: $SCREEN_VERSION"
else
    test_warn "screen nicht verfügbar"
fi

# Test 3: AUTONOMOUS_SERIAL_MONITOR.sh
echo ""
echo "📋 TEST 3: AUTONOMOUS_SERIAL_MONITOR.SH"
echo "────────────────────────────────────────────────────────────────"

if [ -f "AUTONOMOUS_SERIAL_MONITOR.sh" ]; then
    test_pass "AUTONOMOUS_SERIAL_MONITOR.sh vorhanden"
    
    # Check syntax
    if bash -n "AUTONOMOUS_SERIAL_MONITOR.sh" 2>/dev/null; then
        test_pass "AUTONOMOUS_SERIAL_MONITOR.sh Syntax korrekt"
    else
        test_fail "AUTONOMOUS_SERIAL_MONITOR.sh Syntax-Fehler"
    fi
    
    # Check if executable
    if [ -x "AUTONOMOUS_SERIAL_MONITOR.sh" ]; then
        test_pass "AUTONOMOUS_SERIAL_MONITOR.sh ist ausführbar"
    else
        test_warn "AUTONOMOUS_SERIAL_MONITOR.sh ist nicht ausführbar"
        chmod +x "AUTONOMOUS_SERIAL_MONITOR.sh"
        test_pass "AUTONOMOUS_SERIAL_MONITOR.sh ausführbar gemacht"
    fi
    
    # Check configuration
    if grep -q "SERIAL_PORT=" "AUTONOMOUS_SERIAL_MONITOR.sh"; then
        CONFIGURED_PORT=$(grep "SERIAL_PORT=" "AUTONOMOUS_SERIAL_MONITOR.sh" | head -1 | cut -d'"' -f2)
        test_pass "AUTONOMOUS_SERIAL_MONITOR.sh konfiguriert für: $CONFIGURED_PORT"
    else
        test_warn "AUTONOMOUS_SERIAL_MONITOR.sh hat keine SERIAL_PORT Konfiguration"
    fi
    
    if grep -q "BAUDRATE=" "AUTONOMOUS_SERIAL_MONITOR.sh"; then
        CONFIGURED_BAUDRATE=$(grep "BAUDRATE=" "AUTONOMOUS_SERIAL_MONITOR.sh" | head -1 | cut -d'"' -f2)
        test_pass "AUTONOMOUS_SERIAL_MONITOR.sh konfiguriert für Baudrate: $CONFIGURED_BAUDRATE"
    else
        test_warn "AUTONOMOUS_SERIAL_MONITOR.sh hat keine BAUDRATE Konfiguration"
    fi
else
    test_fail "AUTONOMOUS_SERIAL_MONITOR.sh nicht gefunden"
fi

# Test 4: Serial Connection Test (if port available)
echo ""
echo "📋 TEST 4: SERIAL CONNECTION TEST"
echo "────────────────────────────────────────────────────────────────"

if [ -e "$SERIAL_PORT" ] && command -v cu >/dev/null 2>&1; then
    log "Versuche Verbindung zu $SERIAL_PORT..."
    
    # Try to connect (non-blocking, with timeout)
    if timeout 3 cu -l "$SERIAL_PORT" -s "$BAUDRATE" </dev/null >/dev/null 2>&1; then
        test_pass "Serial Verbindung erfolgreich"
    else
        # Check if port is busy
        if lsof "$SERIAL_PORT" >/dev/null 2>&1; then
            test_warn "Serial Port ist belegt (möglicherweise von anderem Prozess)"
            lsof "$SERIAL_PORT" | head -3
        else
            test_warn "Serial Verbindung fehlgeschlagen (möglicherweise Pi nicht eingeschaltet)"
        fi
    fi
else
    test_warn "Serial Connection Test nicht möglich (Port oder Tools nicht verfügbar)"
fi

# Test 5: Boot Log Monitoring
echo ""
echo "📋 TEST 5: BOOT LOG MONITORING"
echo "────────────────────────────────────────────────────────────────"

if [ -f "AUTONOMOUS_SERIAL_MONITOR.sh" ]; then
    # Check if it monitors boot
    if grep -q "boot\|BOOT\|Boot" "AUTONOMOUS_SERIAL_MONITOR.sh"; then
        test_pass "AUTONOMOUS_SERIAL_MONITOR.sh überwacht Boot-Prozess"
    else
        test_warn "AUTONOMOUS_SERIAL_MONITOR.sh überwacht möglicherweise keinen Boot-Prozess"
    fi
    
    # Check if it logs to file
    if grep -q "LOG_FILE\|log.*file" "AUTONOMOUS_SERIAL_MONITOR.sh"; then
        test_pass "AUTONOMOUS_SERIAL_MONITOR.sh loggt in Datei"
    else
        test_warn "AUTONOMOUS_SERIAL_MONITOR.sh loggt möglicherweise nicht in Datei"
    fi
    
    # Check if it detects errors
    if grep -q "ERROR\|error\|Error" "AUTONOMOUS_SERIAL_MONITOR.sh"; then
        test_pass "AUTONOMOUS_SERIAL_MONITOR.sh erkennt Fehler"
    else
        test_warn "AUTONOMOUS_SERIAL_MONITOR.sh erkennt möglicherweise keine Fehler"
    fi
fi

# Test 6: Debugger Integration with Test Suite
echo ""
echo "📋 TEST 6: DEBUGGER INTEGRATION WITH TEST SUITE"
echo "────────────────────────────────────────────────────────────────"

if [ -f "complete_test_suite.sh" ]; then
    if grep -q "DEBUGGER\|debugger" "complete_test_suite.sh"; then
        test_pass "Test-Suite hat Debugger-Integration"
    else
        test_warn "Test-Suite hat möglicherweise keine Debugger-Integration"
    fi
else
    test_warn "complete_test_suite.sh nicht gefunden"
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📊 DEBUGGER TEST SUMMARY                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "=== DEBUGGER TEST SUITE END ==="
log "Log-Datei: $LOG_FILE"
echo ""
echo "✅ Debugger-Tests abgeschlossen"
echo "📋 Log-Datei: $LOG_FILE"
echo ""

