#!/bin/bash
# Complete Test Suite - Works with and without Docker
# Tests all components, services, scripts, and configurations

set +e  # Temporarily disable exit on error for test suite

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_FILE="test-results-$(date +%Y%m%d_%H%M%S).log"
ERRORS=0
WARNINGS=0
TESTS_PASSED=0
TESTS_FAILED=0

log() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date format
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
    else
        echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
    fi
}

test_pass() {
    log "✅ $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    log "❌ $1"
    ERRORS=$((ERRORS + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_warn() {
    log "⚠️  $1"
    WARNINGS=$((WARNINGS + 1))
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 COMPLETE TEST SUITE - ALL COMPONENTS                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "=== COMPLETE TEST SUITE START ==="

# ============================================================================
# TEST 1: CUSTOM SERVICES
# ============================================================================
echo ""
echo "📋 TEST 1: CUSTOM SERVICES"
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
    if [ -f "custom-components/services/$service" ]; then
        test_pass "$service vorhanden"
        
        # Check service content
        if grep -q "\[Unit\]" "custom-components/services/$service"; then
            test_pass "$service hat [Unit] Section"
        else
            test_fail "$service hat keine [Unit] Section"
        fi
        
        if grep -q "\[Service\]" "custom-components/services/$service"; then
            test_pass "$service hat [Service] Section"
        else
            test_fail "$service hat keine [Service] Section"
        fi
        
        if grep -q "\[Install\]" "custom-components/services/$service"; then
            test_pass "$service hat [Install] Section"
        else
            test_fail "$service hat keine [Install] Section"
        fi
    else
        test_fail "$service nicht gefunden"
    fi
done

# ============================================================================
# TEST 2: CUSTOM SCRIPTS
# ============================================================================
echo ""
echo "📋 TEST 2: CUSTOM SCRIPTS"
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
    if [ -f "custom-components/scripts/$script" ]; then
        test_pass "$script vorhanden"
        
        # Check if executable
        if [ -x "custom-components/scripts/$script" ]; then
            test_pass "$script ist ausführbar"
        else
            test_warn "$script ist nicht ausführbar"
        fi
        
        # Check shebang
        if head -1 "custom-components/scripts/$script" | grep -q "^#!"; then
            test_pass "$script hat Shebang"
        else
            test_warn "$script hat keinen Shebang"
        fi
    else
        test_fail "$script nicht gefunden"
    fi
done

# ============================================================================
# TEST 3: BUILD CONFIGURATION
# ============================================================================
echo ""
echo "📋 TEST 3: BUILD CONFIGURATION"
echo "────────────────────────────────────────────────────────────────"

# Check build script
if [ -f "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh" ]; then
    test_pass "Build-Script vorhanden"
    
    # Check for user creation
    if grep -q "useradd.*andre" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
        test_pass "Build-Script erstellt User 'andre'"
    else
        test_fail "Build-Script erstellt User 'andre' nicht"
    fi
    
    # Check for UID 1000
    if grep -q "1000" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh" | grep -q "andre"; then
        test_pass "Build-Script setzt UID 1000 für 'andre'"
    else
        test_warn "Build-Script setzt möglicherweise keine UID 1000"
    fi
    
    # Check for hostname
    if grep -q "GhettoBlaster" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
        test_pass "Build-Script setzt Hostname 'GhettoBlaster'"
    else
        test_fail "Build-Script setzt Hostname 'GhettoBlaster' nicht"
    fi
    
    # Check for password (read from password file)
    PASSWORD_FILE="$SCRIPT_DIR/test-password.txt"
    if [ -f "$PASSWORD_FILE" ]; then
        EXPECTED_PASSWORD=$(cat "$PASSWORD_FILE" | tr -d '\n\r')
    else
        EXPECTED_PASSWORD="4512"
    fi
    
    if grep -q "$EXPECTED_PASSWORD" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
        test_pass "Build-Script setzt Password '$EXPECTED_PASSWORD'"
    else
        test_fail "Build-Script setzt Password '$EXPECTED_PASSWORD' nicht"
    fi
else
    test_fail "Build-Script nicht gefunden"
fi

# ============================================================================
# TEST 4: CONFIG FILES
# ============================================================================
echo ""
echo "📋 TEST 4: CONFIG FILES"
echo "────────────────────────────────────────────────────────────────"

# Check config.txt template
if [ -f "custom-components/configs/config.txt.template" ]; then
    test_pass "config.txt.template vorhanden"
    
    if grep -q "display_rotate=0" "custom-components/configs/config.txt.template"; then
        test_pass "config.txt.template hat display_rotate=0"
    else
        test_fail "config.txt.template hat kein display_rotate=0"
    fi
    
    if grep -q "hdmi_force_mode=1" "custom-components/configs/config.txt.template"; then
        test_pass "config.txt.template hat hdmi_force_mode=1"
    else
        test_warn "config.txt.template hat kein hdmi_force_mode=1"
    fi
else
    test_warn "config.txt.template nicht gefunden"
fi

# Check INTEGRATE script
if [ -f "INTEGRATE_CUSTOM_COMPONENTS.sh" ]; then
    test_pass "INTEGRATE_CUSTOM_COMPONENTS.sh vorhanden"
    
    if grep -q "display_rotate=0" "INTEGRATE_CUSTOM_COMPONENTS.sh"; then
        test_pass "INTEGRATE script hat display_rotate=0"
    else
        test_fail "INTEGRATE script hat kein display_rotate=0"
    fi
else
    test_fail "INTEGRATE_CUSTOM_COMPONENTS.sh nicht gefunden"
fi

# ============================================================================
# TEST 5: DOCKER FILES
# ============================================================================
echo ""
echo "📋 TEST 5: DOCKER FILES"
echo "────────────────────────────────────────────────────────────────"

DOCKER_FILES=(
    "Dockerfile.system-sim"
    "Dockerfile.system-sim-simple"
    "docker-compose.system-sim.yml"
    "docker-compose.system-sim-simple.yml"
)

for docker_file in "${DOCKER_FILES[@]}"; do
    if [ -f "$docker_file" ]; then
        test_pass "$docker_file vorhanden"
    else
        test_warn "$docker_file nicht gefunden"
    fi
done

# ============================================================================
# TEST 6: TEST SCRIPTS
# ============================================================================
echo ""
echo "📋 TEST 6: TEST SCRIPTS"
echo "────────────────────────────────────────────────────────────────"

TEST_SCRIPTS=(
    "system-sim-test/comprehensive-test.sh"
    "system-sim-test/boot-simulation.sh"
    "START_SYSTEM_SIMULATION.sh"
    "START_SYSTEM_SIMULATION_SIMPLE.sh"
)

for test_script in "${TEST_SCRIPTS[@]}"; do
    if [ -f "$test_script" ]; then
        test_pass "$test_script vorhanden"
        
        if [ -x "$test_script" ]; then
            test_pass "$test_script ist ausführbar"
        else
            test_warn "$test_script ist nicht ausführbar"
        fi
    else
        test_warn "$test_script nicht gefunden"
    fi
done

# ============================================================================
# TEST 7: BOOT BLOCKER FIXES
# ============================================================================
echo ""
echo "📋 TEST 7: BOOT BLOCKER FIXES"
echo "────────────────────────────────────────────────────────────────"

# Test cloud-init fix
if [ -f "moode-source/lib/systemd/system/06-disable-cloud-init.service" ]; then
    test_pass "06-disable-cloud-init.service vorhanden"
    
    if grep -q "DefaultDependencies=no" "moode-source/lib/systemd/system/06-disable-cloud-init.service"; then
        test_pass "06-disable-cloud-init.service hat DefaultDependencies=no"
    else
        test_fail "06-disable-cloud-init.service hat kein DefaultDependencies=no"
    fi
    
    if grep -q "Conflicts=cloud-init.target" "moode-source/lib/systemd/system/06-disable-cloud-init.service"; then
        test_pass "06-disable-cloud-init.service hat Conflicts="
    else
        test_fail "06-disable-cloud-init.service hat kein Conflicts="
    fi
else
    test_fail "06-disable-cloud-init.service nicht gefunden"
fi

# Test build script cloud-init disable
if grep -q "Disable cloud-init" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
    test_pass "Build-Script deaktiviert cloud-init"
    
    if grep -q "cloud-init.target.d/override.conf" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
        test_pass "Build-Script erstellt cloud-init override"
    else
        test_fail "Build-Script erstellt kein cloud-init override"
    fi
    
    if grep -q "ln -sf /dev/null.*cloud-init.target" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
        test_pass "Build-Script maskiert cloud-init.target"
    else
        test_fail "Build-Script maskiert cloud-init.target nicht"
    fi
else
    test_fail "Build-Script deaktiviert cloud-init nicht"
fi

# Test NetworkManager-wait-online fix in build script
if grep -q "NetworkManager-wait-online" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
    test_pass "Build-Script deaktiviert NetworkManager-wait-online"
    
    if grep -q "NetworkManager-wait-online.service.d/override.conf" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
        test_pass "Build-Script erstellt NetworkManager-wait-online override"
    else
        test_fail "Build-Script erstellt kein NetworkManager-wait-online override"
    fi
else
    test_fail "Build-Script deaktiviert NetworkManager-wait-online nicht"
fi

# ============================================================================
# TEST 8: USERNAME PERSISTENCE FIXES
# ============================================================================
echo ""
echo "📋 TEST 8: USERNAME PERSISTENCE FIXES"
echo "────────────────────────────────────────────────────────────────"

# Test sysutil.sh fix
if [ -f "moode-source/www/util/sysutil.sh" ]; then
    if grep -q "FIX: Prefer andre" "moode-source/www/util/sysutil.sh"; then
        test_pass "sysutil.sh hat Username-Persistenz-Fix"
        
        if grep -q "WARNING: Using 'pi' user" "moode-source/www/util/sysutil.sh"; then
            test_pass "sysutil.sh warnt bei pi user"
        else
            test_warn "sysutil.sh warnt nicht bei pi user"
        fi
    else
        test_fail "sysutil.sh hat keinen Username-Persistenz-Fix"
    fi
else
    test_fail "sysutil.sh nicht gefunden"
fi

# Test common.php fix
if [ -f "moode-source/www/inc/common.php" ]; then
    if grep -q "CRITICAL: If pi also exists" "moode-source/www/inc/common.php"; then
        test_pass "common.php hat Username-Persistenz-Fix"
        
        if grep -q "userdel -r pi" "moode-source/www/inc/common.php"; then
            test_pass "common.php entfernt pi user automatisch"
        else
            test_fail "common.php entfernt pi user nicht automatisch"
        fi
    else
        test_fail "common.php hat keinen Username-Persistenz-Fix"
    fi
else
    test_fail "common.php nicht gefunden"
fi

# Test build script pi user removal
if grep -q "CRITICAL FIX: Remove pi user" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
    test_pass "Build-Script entfernt pi user"
    
    if grep -q "userdel -r pi" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"; then
        test_pass "Build-Script verwendet userdel für pi"
    else
        test_fail "Build-Script verwendet nicht userdel für pi"
    fi
else
    test_fail "Build-Script entfernt pi user nicht"
fi

# Test 05-remove-pi-user.service
if [ -f "moode-source/lib/systemd/system/05-remove-pi-user.service" ]; then
    test_pass "05-remove-pi-user.service vorhanden"
    
    if grep -q "userdel -r pi" "moode-source/lib/systemd/system/05-remove-pi-user.service"; then
        test_pass "05-remove-pi-user.service entfernt pi user"
    else
        test_fail "05-remove-pi-user.service entfernt pi user nicht"
    fi
else
    test_fail "05-remove-pi-user.service nicht gefunden"
fi

# ============================================================================
# TEST 9: NETWORK CONFIGURATION
# ============================================================================
echo ""
echo "📋 TEST 9: NETWORK CONFIGURATION"
echo "────────────────────────────────────────────────────────────────"

# Test early boot network service
if [ -f "moode-source/lib/systemd/system/00-boot-network-ssh.service" ]; then
    test_pass "00-boot-network-ssh.service vorhanden"
    
    if grep -q "192.168.10.2" "moode-source/lib/systemd/system/00-boot-network-ssh.service"; then
        test_pass "00-boot-network-ssh.service konfiguriert 192.168.10.2"
    else
        test_fail "00-boot-network-ssh.service konfiguriert nicht 192.168.10.2"
    fi
else
    test_fail "00-boot-network-ssh.service nicht gefunden"
fi

# Test SSH enable service
if [ -f "moode-source/lib/systemd/system/01-ssh-enable.service" ]; then
    test_pass "01-ssh-enable.service vorhanden"
else
    test_fail "01-ssh-enable.service nicht gefunden"
fi

# Test eth0 configure service
if [ -f "moode-source/lib/systemd/system/02-eth0-configure.service" ]; then
    test_pass "02-eth0-configure.service vorhanden"
    
    if grep -q "192.168.10.2" "moode-source/lib/systemd/system/02-eth0-configure.service"; then
        test_pass "02-eth0-configure.service konfiguriert 192.168.10.2"
    else
        test_fail "02-eth0-configure.service konfiguriert nicht 192.168.10.2"
    fi
else
    test_fail "02-eth0-configure.service nicht gefunden"
fi

# ============================================================================
# TEST 10: SERVICE NAMING CONVENTION
# ============================================================================
echo ""
echo "📋 TEST 10: SERVICE NAMING CONVENTION"
echo "────────────────────────────────────────────────────────────────"

# Check for status-descriptive names (should NOT exist)
BAD_NAMES=(
    "guaranteed"
    "bulletproof"
    "complete"
    "minimal"
    "direct"
    "force"
    "unblock"
)

for bad_name in "${BAD_NAMES[@]}"; do
    if find moode-source/lib/systemd/system -name "*${bad_name}*.service" 2>/dev/null | grep -q .; then
        test_fail "Service mit Status-Beschreibung gefunden: *${bad_name}*"
    else
        test_pass "Kein Service mit Status-Beschreibung: *${bad_name}*"
    fi
done

# Check for chronological names (should exist)
CHRONO_SERVICES=(
    "00-boot-network-ssh.service"
    "01-ssh-enable.service"
    "02-eth0-configure.service"
    "03-network-configure.service"
    "05-remove-pi-user.service"
    "06-disable-cloud-init.service"
)

for service in "${CHRONO_SERVICES[@]}"; do
    if [ -f "moode-source/lib/systemd/system/$service" ]; then
        test_pass "$service vorhanden (chronologisch benannt)"
    else
        test_warn "$service nicht gefunden"
    fi
done

# ============================================================================
# TEST 11: SD CARD VERIFICATION (if mounted)
# ============================================================================
echo ""
echo "📋 TEST 11: SD CARD VERIFICATION"
echo "────────────────────────────────────────────────────────────────"

if [ -d "/Volumes/rootfs" ]; then
    test_pass "SD card rootfs gemountet"
    
    # Test cloud-init override on SD card
    if [ -f "/Volumes/rootfs/etc/systemd/system/cloud-init.target.d/override.conf" ]; then
        test_pass "Cloud-init override auf SD card vorhanden"
    else
        test_fail "Cloud-init override auf SD card nicht vorhanden"
    fi
    
    # Test cloud-init.target masked on SD card
    if [ -L "/Volumes/rootfs/etc/systemd/system/cloud-init.target" ]; then
        test_pass "cloud-init.target auf SD card maskiert"
    else
        test_fail "cloud-init.target auf SD card nicht maskiert"
    fi
    
    # Test NetworkManager-wait-online override on SD card
    if [ -f "/Volumes/rootfs/etc/systemd/system/NetworkManager-wait-online.service.d/override.conf" ]; then
        test_pass "NetworkManager-wait-online override auf SD card vorhanden"
    else
        test_fail "NetworkManager-wait-online override auf SD card nicht vorhanden"
    fi
    
    # Test NetworkManager-wait-online masked on SD card
    if [ -L "/Volumes/rootfs/etc/systemd/system/NetworkManager-wait-online.service" ]; then
        test_pass "NetworkManager-wait-online auf SD card maskiert"
    else
        test_fail "NetworkManager-wait-online auf SD card nicht maskiert"
    fi
    
    # Test username persistence fixes on SD card
    if [ -f "/Volumes/rootfs/var/www/html/util/sysutil.sh" ]; then
        if grep -q "FIX: Prefer andre" "/Volumes/rootfs/var/www/html/util/sysutil.sh" 2>/dev/null; then
            test_pass "sysutil.sh Fix auf SD card vorhanden"
        else
            test_fail "sysutil.sh Fix auf SD card nicht vorhanden"
        fi
    else
        test_warn "sysutil.sh auf SD card nicht gefunden"
    fi
    
    if [ -f "/Volumes/rootfs/var/www/html/inc/common.php" ]; then
        if grep -q "CRITICAL: If pi also exists" "/Volumes/rootfs/var/www/html/inc/common.php" 2>/dev/null; then
            test_pass "common.php Fix auf SD card vorhanden"
        else
            test_fail "common.php Fix auf SD card nicht vorhanden"
        fi
    else
        test_warn "common.php auf SD card nicht gefunden"
    fi
    
    # Test services on SD card
    for service in "${CHRONO_SERVICES[@]}"; do
        if [ -f "/Volumes/rootfs/lib/systemd/system/$service" ]; then
            test_pass "$service auf SD card vorhanden"
        else
            test_warn "$service auf SD card nicht gefunden"
        fi
    done
else
    test_warn "SD card nicht gemountet - Überspringe SD card Tests"
fi

# ============================================================================
# TEST 12: BUILD SCRIPT COMPLETENESS
# ============================================================================
echo ""
echo "📋 TEST 12: BUILD SCRIPT COMPLETENESS"
echo "────────────────────────────────────────────────────────────────"

BUILD_SCRIPT="imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh"

if [ -f "$BUILD_SCRIPT" ]; then
    # Check all critical fixes are in build script
    CRITICAL_CHECKS=(
        "useradd.*andre"
        "UID 1000"
        "test-password.txt"
        "Disable cloud-init"
        "cloud-init.target.d/override.conf"
        "NetworkManager-wait-online"
        "CRITICAL FIX: Remove pi user"
    )
    
    for check in "${CRITICAL_CHECKS[@]}"; do
        if grep -q "$check" "$BUILD_SCRIPT"; then
            test_pass "Build-Script enthält: $check"
        else
            test_fail "Build-Script enthält nicht: $check"
        fi
    done
    
    # Check service enabling
    if grep -q "systemctl enable.*01-ssh-enable.service" "$BUILD_SCRIPT"; then
        test_pass "Build-Script aktiviert 01-ssh-enable.service"
    else
        test_warn "Build-Script aktiviert 01-ssh-enable.service nicht explizit"
    fi
else
    test_fail "Build-Script nicht gefunden"
fi

# ============================================================================
# TEST 13: DOCKER FUNCTIONALITY
# ============================================================================
echo ""
echo "📋 TEST 13: DOCKER FUNCTIONALITY"
echo "────────────────────────────────────────────────────────────────"

if command -v docker >/dev/null 2>&1; then
    test_pass "Docker installiert"
    
    if docker ps >/dev/null 2>&1; then
        test_pass "Docker Daemon läuft"
        
        # Try to build test image
        if docker build -t test-suite:latest -f Dockerfile.system-sim-simple . >/dev/null 2>&1; then
            test_pass "Docker Build funktioniert"
        else
            test_warn "Docker Build fehlgeschlagen"
        fi
    else
        test_warn "Docker Daemon läuft nicht"
    fi
else
    test_warn "Docker nicht installiert"
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
log "Tests Passed: $TESTS_PASSED"
log "Tests Failed: $TESTS_FAILED"
log "Warnings: $WARNINGS"
log "Errors: $ERRORS"

echo ""
echo "✅ Tests Passed: $TESTS_PASSED"
echo "❌ Tests Failed: $TESTS_FAILED"
echo "⚠️  Warnings: $WARNINGS"
echo "🔴 Errors: $ERRORS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ ALLE KRITISCHEN TESTS ERFOLGREICH                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    log "✅ ALLE KRITISCHEN TESTS ERFOLGREICH"
    exit 0
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ❌ $ERRORS FEHLER GEFUNDEN                                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    log "❌ $ERRORS FEHLER GEFUNDEN"
    exit 1
fi
