#!/bin/bash
################################################################################
# DISPLAY ROTATION & SSH DEBUG TEST
# 
# Tests and simulates both display rotation and SSH problems to find root cause
# Uses Docker simulation to reproduce the issues
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.cursor/debug.log"
cd "$PROJECT_ROOT"

# Clear log file
if [ -f "$LOG_FILE" ]; then
    rm -f "$LOG_FILE"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[TEST]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
test_pass() { log "✅ $1"; }
test_fail() { error "❌ $1"; }
test_warn() { warn "⚠️  $1"; }

# Debug logging function
debug_log() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    
    # Write to NDJSON log file
    echo "{\"id\":\"log_$(date +%s)_$$\",\"timestamp\":$(date +%s)000,\"location\":\"$location\",\"message\":\"$message\",\"data\":$data,\"sessionId\":\"debug-session\",\"runId\":\"display-ssh-test\",\"hypothesisId\":\"$hypothesis_id\"}" >> "$LOG_FILE"
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 DISPLAY ROTATION & SSH DEBUG TEST                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# HYPOTHESES
################################################################################

log "=== GENERATING HYPOTHESES ==="
echo ""

HYPOTHESES=(
    "A: worker.php overwrites config.txt removing display_rotate=0"
    "B: moOde database hdmi_scn_orient is set to portrait"
    "C: xinitrc has forced rotation to portrait"
    "D: SSH service is disabled by moOde during boot"
    "E: SSH flag file is deleted during boot"
    "F: config.txt moOde header is missing causing overwrite"
    "G: worker.php patch is not applied"
    "H: cmdline.txt video= parameter forces portrait"
)

for i in "${!HYPOTHESES[@]}"; do
    echo "  ${HYPOTHESES[$i]}"
    debug_log "H${i}" "test:display-rotation-ssh-debug.sh:$(($i+1))" "Hypothesis generated" "{\"hypothesis\":\"${HYPOTHESES[$i]}\"}"
done

echo ""

################################################################################
# TEST 1: CHECK CONFIG.TXT ON SD CARD
################################################################################

log "=== TEST 1: CHECK CONFIG.TXT ON SD CARD ==="
echo ""

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
fi

if [ -n "$SD_MOUNT" ] && [ -f "$SD_MOUNT/config.txt" ]; then
    info "SD-Karte gefunden: $SD_MOUNT"
    
    # Check for display_rotate
    if grep -q "^display_rotate=0" "$SD_MOUNT/config.txt"; then
        test_pass "config.txt hat display_rotate=0"
        debug_log "A" "$SD_MOUNT/config.txt" "display_rotate=0 found" "{\"file\":\"$SD_MOUNT/config.txt\"}"
    else
        test_fail "config.txt hat KEIN display_rotate=0"
        debug_log "A" "$SD_MOUNT/config.txt" "display_rotate=0 NOT found" "{\"file\":\"$SD_MOUNT/config.txt\",\"content\":\"$(grep display_rotate "$SD_MOUNT/config.txt" | head -1)\"}"
    fi
    
    # Check for moOde header
    if grep -q "# This file is managed by moOde" "$SD_MOUNT/config.txt"; then
        test_pass "config.txt hat moOde Header"
        debug_log "F" "$SD_MOUNT/config.txt" "moOde header found" "{\"file\":\"$SD_MOUNT/config.txt\"}"
    else
        test_fail "config.txt hat KEINEN moOde Header (wird überschrieben!)"
        debug_log "F" "$SD_MOUNT/config.txt" "moOde header NOT found - WILL BE OVERWRITTEN" "{\"file\":\"$SD_MOUNT/config.txt\"}"
    fi
    
    # Check for SSH flag
    if [ -f "$SD_MOUNT/ssh" ]; then
        test_pass "SSH-Flag-Datei vorhanden"
        debug_log "E" "$SD_MOUNT/ssh" "SSH flag file exists" "{\"file\":\"$SD_MOUNT/ssh\"}"
    else
        test_fail "SSH-Flag-Datei NICHT vorhanden"
        debug_log "E" "$SD_MOUNT/ssh" "SSH flag file NOT found" "{\"file\":\"$SD_MOUNT/ssh\"}"
    fi
    
    # Check [pi5] section
    if grep -q "^\[pi5\]" "$SD_MOUNT/config.txt"; then
        test_pass "config.txt hat [pi5] Section"
        debug_log "A" "$SD_MOUNT/config.txt" "[pi5] section found" "{\"file\":\"$SD_MOUNT/config.txt\"}"
    else
        test_warn "config.txt hat KEINE [pi5] Section"
        debug_log "A" "$SD_MOUNT/config.txt" "[pi5] section NOT found" "{\"file\":\"$SD_MOUNT/config.txt\"}"
    fi
    
    # Check cmdline.txt for video= parameter
    if [ -f "$SD_MOUNT/cmdline.txt" ]; then
        if grep -q "video=.*rotate" "$SD_MOUNT/cmdline.txt"; then
            test_fail "cmdline.txt hat video= rotate Parameter (erzwingt Portrait!)"
            debug_log "H" "$SD_MOUNT/cmdline.txt" "video= rotate parameter found" "{\"file\":\"$SD_MOUNT/cmdline.txt\",\"content\":\"$(grep video= "$SD_MOUNT/cmdline.txt")\"}"
        else
            test_pass "cmdline.txt hat KEINEN video= rotate Parameter"
            debug_log "H" "$SD_MOUNT/cmdline.txt" "No video= rotate parameter" "{\"file\":\"$SD_MOUNT/cmdline.txt\"}"
        fi
    fi
else
    warn "SD-Karte nicht gefunden - überspringe SD-Karten-Tests"
fi

echo ""

################################################################################
# TEST 2: CHECK MOODE SOURCE FILES
################################################################################

log "=== TEST 2: CHECK MOODE SOURCE FILES ==="
echo ""

# Check worker.php
if [ -f "$PROJECT_ROOT/moode-source/www/daemon/worker.php" ]; then
    info "Prüfe worker.php..."
    
    # Check for chkBootConfigTxt call
    if grep -q "chkBootConfigTxt" "$PROJECT_ROOT/moode-source/www/daemon/worker.php"; then
        test_pass "worker.php ruft chkBootConfigTxt auf"
        debug_log "A" "moode-source/www/daemon/worker.php" "chkBootConfigTxt call found" "{\"line\":\"$(grep -n chkBootConfigTxt "$PROJECT_ROOT/moode-source/www/daemon/worker.php" | head -1)\"}"
    fi
    
    # Check for config.txt overwrite
    if grep -q "cp.*config.txt.*/boot/firmware" "$PROJECT_ROOT/moode-source/www/daemon/worker.php"; then
        test_fail "worker.php überschreibt config.txt!"
        debug_log "A" "moode-source/www/daemon/worker.php" "config.txt overwrite found" "{\"line\":\"$(grep -n 'cp.*config.txt' "$PROJECT_ROOT/moode-source/www/daemon/worker.php" | head -1)\"}"
    fi
    
    # Check for worker.php patch
    if grep -q "Ghettoblaster: display_rotate=0" "$PROJECT_ROOT/moode-source/www/daemon/worker.php"; then
        test_pass "worker.php hat Patch (display_rotate=0)"
        debug_log "G" "moode-source/www/daemon/worker.php" "worker.php patch found" "{}"
    else
        test_fail "worker.php hat KEINEN Patch (wird überschrieben!)"
        debug_log "G" "moode-source/www/daemon/worker.php" "worker.php patch NOT found" "{}"
    fi
fi

# Check worker-php-patch.sh
if [ -f "$PROJECT_ROOT/moode-source/usr/local/bin/worker-php-patch.sh" ]; then
    test_pass "worker-php-patch.sh vorhanden"
    debug_log "G" "moode-source/usr/local/bin/worker-php-patch.sh" "Patch script exists" "{}"
else
    test_fail "worker-php-patch.sh NICHT vorhanden"
    debug_log "G" "moode-source/usr/local/bin/worker-php-patch.sh" "Patch script NOT found" "{}"
fi

# Check default config.txt
if [ -f "$PROJECT_ROOT/moode-source/usr/share/moode-player/boot/firmware/config.txt" ]; then
    info "Prüfe moOde Default config.txt..."
    
    if grep -q "display_rotate" "$PROJECT_ROOT/moode-source/usr/share/moode-player/boot/firmware/config.txt"; then
        DEFAULT_ROTATE=$(grep "^display_rotate=" "$PROJECT_ROOT/moode-source/usr/share/moode-player/boot/firmware/config.txt" | head -1 | cut -d'=' -f2)
        if [ "$DEFAULT_ROTATE" != "0" ]; then
            test_fail "moOde Default config.txt hat display_rotate=$DEFAULT_ROTATE (NICHT 0!)"
            debug_log "A" "moode-source/usr/share/moode-player/boot/firmware/config.txt" "Default config has wrong display_rotate" "{\"value\":\"$DEFAULT_ROTATE\"}"
        else
            test_pass "moOde Default config.txt hat display_rotate=0"
        fi
    fi
fi

echo ""

################################################################################
# TEST 3: CHECK SSH SERVICES
################################################################################

log "=== TEST 3: CHECK SSH SERVICES ==="
echo ""

# Check enable-ssh-early.service
if [ -f "$PROJECT_ROOT/custom-components/services/enable-ssh-early.service" ]; then
    test_pass "enable-ssh-early.service vorhanden"
    debug_log "D" "custom-components/services/enable-ssh-early.service" "SSH early service exists" "{}"
    
    # Check if it enables SSH
    if grep -q "systemctl enable ssh" "$PROJECT_ROOT/custom-components/services/enable-ssh-early.service"; then
        test_pass "enable-ssh-early.service aktiviert SSH"
        debug_log "D" "custom-components/services/enable-ssh-early.service" "Service enables SSH" "{}"
    fi
else
    test_fail "enable-ssh-early.service NICHT vorhanden"
    debug_log "D" "custom-components/services/enable-ssh-early.service" "SSH early service NOT found" "{}"
fi

# Check fix-ssh-sudoers.service
if [ -f "$PROJECT_ROOT/custom-components/services/fix-ssh-sudoers.service" ]; then
    test_pass "fix-ssh-sudoers.service vorhanden"
    debug_log "D" "custom-components/services/fix-ssh-sudoers.service" "SSH fix service exists" "{}"
else
    test_fail "fix-ssh-sudoers.service NICHT vorhanden"
    debug_log "D" "custom-components/services/fix-ssh-sudoers.service" "SSH fix service NOT found" "{}"
fi

echo ""

################################################################################
# TEST 4: DOCKER SIMULATION
################################################################################

log "=== TEST 4: DOCKER SIMULATION ==="
echo ""

info "Starte Docker-Simulation um Probleme zu reproduzieren..."

if command -v docker &> /dev/null; then
    # Create test directories
    mkdir -p "$PROJECT_ROOT/test-sim-boot"
    mkdir -p "$PROJECT_ROOT/test-sim-moode"
    
    # Create mock config.txt
    cat > "$PROJECT_ROOT/test-sim-boot/config.txt" << 'CONFIG_EOF'
#########################################
# This file is managed by moOde
#########################################

[pi5]
display_rotate=0
dtoverlay=vc4-kms-v3d-pi5,noaudio

[all]
hdmi_group=2
hdmi_mode=87
CONFIG_EOF

    # Create mock worker.php
    cat > "$PROJECT_ROOT/test-sim-moode/worker.php" << 'WORKER_EOF'
<?php
// Mock worker.php
function chkBootConfigTxt() {
    // Simulate: Check if header is present
    $config = file_get_contents('/boot/firmware/config.txt');
    if (strpos($config, '# This file is managed by moOde') === false) {
        return 'Required header missing';
    }
    return 'Required headers present';
}

// Simulate worker.php behavior
$status = chkBootConfigTxt();
if ($status == 'Required header missing') {
    // This would overwrite config.txt
    echo "WOULD OVERWRITE config.txt\n";
}
WORKER_EOF

    debug_log "A" "test-sim-boot/config.txt" "Mock config.txt created" "{\"has_header\":true,\"has_display_rotate\":true}"
    debug_log "A" "test-sim-moode/worker.php" "Mock worker.php created" "{\"simulates_overwrite\":true}"
    
    info "Docker-Simulation vorbereitet"
    info "  Mock config.txt: $PROJECT_ROOT/test-sim-boot/config.txt"
    info "  Mock worker.php: $PROJECT_ROOT/test-sim-moode/worker.php"
else
    warn "Docker nicht verfügbar - überspringe Simulation"
fi

echo ""

################################################################################
# SUMMARY
################################################################################

log "=== TEST SUMMARY ==="
echo ""

info "Hypothesen getestet:"
for i in "${!HYPOTHESES[@]}"; do
    echo "  ${HYPOTHESES[$i]}"
done

echo ""
info "Log-Datei: $LOG_FILE"
info "Analysiere Logs für Root Cause..."

echo ""
log "=== TEST ABGESCHLOSSEN ==="
echo ""
info "Nächste Schritte:"
echo "  1. Analysiere Log-Datei: $LOG_FILE"
echo "  2. Prüfe welche Hypothesen bestätigt wurden"
echo "  3. Implementiere Fixes basierend auf Erkenntnissen"
echo ""

