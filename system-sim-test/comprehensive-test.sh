#!/bin/bash
# Comprehensive System Simulation Test
# Tests all components, services, and fixes

set -e

LOG_FILE="/test/test-results.log"
ERRORS=0
WARNINGS=0

log() {
    if command -v date >/dev/null 2>&1; then
        if date --version >/dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
        else
            echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOG_FILE"
        fi
    else
        echo "[$(date)] $1" | tee -a "$LOG_FILE"
    fi
}

test_pass() {
    log "✅ $1"
}

test_fail() {
    log "❌ $1"
    ERRORS=$((ERRORS + 1))
}

test_warn() {
    log "⚠️  $1"
    WARNINGS=$((WARNINGS + 1))
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 SYSTEM SIMULATION - COMPREHENSIVE TESTS                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

log "=== SYSTEM SIMULATION TEST START ==="

# Wait for systemd
log "⏳ Warte auf systemd..."
sleep 10

# ============================================================================
# TEST 1: USER CONFIGURATION
# ============================================================================
echo ""
echo "📋 TEST 1: USER CONFIGURATION"
echo "────────────────────────────────────────────────────────────────"

# Test 1.1: User andre exists
if id -u andre >/dev/null 2>&1; then
    test_pass "User 'andre' existiert"
else
    test_fail "User 'andre' existiert nicht"
    exit 1
fi

# Test 1.2: UID 1000
ANDRE_UID=$(id -u andre)
if [ "$ANDRE_UID" = "1000" ]; then
    test_pass "User 'andre' hat UID 1000"
else
    test_fail "User 'andre' hat UID $ANDRE_UID (sollte 1000 sein)"
fi

# Test 1.3: GID 1000
ANDRE_GID=$(id -g andre)
if [ "$ANDRE_GID" = "1000" ]; then
    test_pass "User 'andre' hat GID 1000"
else
    test_fail "User 'andre' hat GID $ANDRE_GID (sollte 1000 sein)"
fi

# Test 1.4: Password
if echo "0815" | su - andre -c "true" 2>/dev/null; then
    test_pass "Password für 'andre' funktioniert"
else
    test_warn "Password-Test nicht möglich (normal in Docker)"
fi

# Test 1.5: Groups
GROUPS=$(groups andre)
if echo "$GROUPS" | grep -q "sudo"; then
    test_pass "User 'andre' ist in Gruppe 'sudo'"
else
    test_fail "User 'andre' ist nicht in Gruppe 'sudo'"
fi

# ============================================================================
# TEST 2: HOSTNAME
# ============================================================================
echo ""
echo "📋 TEST 2: HOSTNAME"
echo "────────────────────────────────────────────────────────────────"

HOSTNAME=$(hostname)
if [ "$HOSTNAME" = "GhettoBlaster" ]; then
    test_pass "Hostname ist 'GhettoBlaster'"
else
    test_fail "Hostname ist '$HOSTNAME' (sollte 'GhettoBlaster' sein)"
fi

# ============================================================================
# TEST 3: SSH CONFIGURATION
# ============================================================================
echo ""
echo "📋 TEST 3: SSH CONFIGURATION"
echo "────────────────────────────────────────────────────────────────"

# Test 3.1: SSH enabled
if systemctl is-enabled ssh >/dev/null 2>&1 || systemctl is-enabled sshd >/dev/null 2>&1; then
    test_pass "SSH ist enabled"
else
    test_warn "SSH ist nicht enabled (wird von Services aktiviert)"
fi

# Test 3.2: SSH flag
if [ -f "/boot/firmware/ssh" ]; then
    test_pass "SSH-Flag vorhanden (/boot/firmware/ssh)"
else
    test_warn "SSH-Flag nicht gefunden (wird von Services erstellt)"
fi

# ============================================================================
# TEST 4: SUDOERS
# ============================================================================
echo ""
echo "📋 TEST 4: SUDOERS"
echo "────────────────────────────────────────────────────────────────"

# Test 4.1: Sudoers file exists
if [ -f "/etc/sudoers.d/andre" ]; then
    test_pass "Sudoers-Datei vorhanden (/etc/sudoers.d/andre)"
else
    test_fail "Sudoers-Datei nicht gefunden"
fi

# Test 4.2: NOPASSWD
if grep -q "NOPASSWD" /etc/sudoers.d/andre 2>/dev/null; then
    test_pass "Sudoers enthält NOPASSWD"
else
    test_fail "Sudoers enthält kein NOPASSWD"
fi

# Test 4.3: Sudo works
if sudo -n true 2>/dev/null; then
    test_pass "Sudo funktioniert ohne Passwort"
else
    test_fail "Sudo funktioniert nicht ohne Passwort"
fi

# ============================================================================
# TEST 5: SERVICES
# ============================================================================
echo ""
echo "📋 TEST 5: CUSTOM SERVICES"
echo "────────────────────────────────────────────────────────────────"

SERVICES=(
    "enable-ssh-early.service"
    "fix-ssh-sudoers.service"
    "fix-user-id.service"
    "localdisplay.service"
    "disable-console.service"
    "xserver-ready.service"
    "ft6236-delay.service"
    "i2c-monitor.service"
    "i2c-stabilize.service"
    "audio-optimize.service"
    "peppymeter.service"
    "peppymeter-extended-displays.service"
)

for service in "${SERVICES[@]}"; do
    if [ -f "/lib/systemd/system/$service" ] || [ -f "/lib/systemd/system/custom/$service" ]; then
        test_pass "$service vorhanden"
        
        # Try to enable service (may fail in simulation, that's OK)
        if systemctl enable "$service" 2>/dev/null; then
            test_pass "$service enabled"
        else
            test_warn "$service konnte nicht enabled werden (normal in Simulation)"
        fi
    else
        test_warn "$service nicht gefunden"
    fi
done

# ============================================================================
# TEST 6: SCRIPTS
# ============================================================================
echo ""
echo "📋 TEST 6: CUSTOM SCRIPTS"
echo "────────────────────────────────────────────────────────────────"

SCRIPTS=(
    "start-chromium-clean.sh"
    "xserver-ready.sh"
    "worker-php-patch.sh"
    "i2c-stabilize.sh"
    "i2c-monitor.sh"
    "audio-optimize.sh"
    "pcm5122-oversampling.sh"
    "peppymeter-extended-displays.py"
    "generate-fir-filter.py"
    "analyze-measurement.py"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "/usr/local/bin/$script" ] || [ -f "/usr/local/bin/custom/$script" ]; then
        test_pass "$script vorhanden"
        
        # Check if executable
        if [ -x "/usr/local/bin/$script" ] || [ -x "/usr/local/bin/custom/$script" ]; then
            test_pass "$script ist ausführbar"
        else
            test_warn "$script ist nicht ausführbar"
        fi
    else
        test_warn "$script nicht gefunden"
    fi
done

# ============================================================================
# TEST 7: BOOT CONFIGURATION
# ============================================================================
echo ""
echo "📋 TEST 7: BOOT CONFIGURATION"
echo "────────────────────────────────────────────────────────────────"

# Test 7.1: config.txt
if [ -f "/boot/firmware/config.txt" ]; then
    test_pass "config.txt vorhanden"
    
    # Test display_rotate
    if grep -q "display_rotate=0" /boot/firmware/config.txt 2>/dev/null; then
        test_pass "config.txt enthält display_rotate=0"
    else
        test_warn "config.txt enthält kein display_rotate=0"
    fi
    
    # Test hdmi_force_mode
    if grep -q "hdmi_force_mode=1" /boot/firmware/config.txt 2>/dev/null; then
        test_pass "config.txt enthält hdmi_force_mode=1"
    else
        test_warn "config.txt enthält kein hdmi_force_mode=1"
    fi
else
    test_warn "config.txt nicht gefunden"
fi

# ============================================================================
# TEST 8: SYSTEMD STATUS
# ============================================================================
echo ""
echo "📋 TEST 8: SYSTEMD STATUS"
echo "────────────────────────────────────────────────────────────────"

SYSTEMD_STATUS=$(systemctl is-system-running 2>/dev/null || echo "unknown")
if [ "$SYSTEMD_STATUS" = "running" ] || [ "$SYSTEMD_STATUS" = "degraded" ]; then
    test_pass "systemd läuft ($SYSTEMD_STATUS)"
else
    test_warn "systemd Status: $SYSTEMD_STATUS"
fi

# ============================================================================
# TEST SUMMARY
# ============================================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📊 TEST SUMMARY                                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "=== TEST SUMMARY ==="
log "Errors: $ERRORS"
log "Warnings: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    echo "✅ ALLE KRITISCHEN TESTS ERFOLGREICH"
    log "✅ ALLE KRITISCHEN TESTS ERFOLGREICH"
    exit 0
else
    echo "❌ $ERRORS FEHLER GEFUNDEN"
    log "❌ $ERRORS FEHLER GEFUNDEN"
    exit 1
fi

