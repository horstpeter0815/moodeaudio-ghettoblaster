#!/bin/bash
# Verify Architecture
# Verify system matches documented architecture in MASTER_MOODE_ARCHITECTURE.md
# Part of: WISSENSBASIS/DEVELOPMENT_WORKFLOW.md tooling

set -e

PI_IP="${1:-192.168.2.3}"
USER="${2:-andre}"

echo "========================================"
echo "Architecture Verification"
echo "Target: $USER@$PI_IP"
echo "Reference: WISSENSBASIS/MASTER_MOODE_ARCHITECTURE.md"
echo "========================================"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# Helper functions
check_pass() {
    echo "✓ $1"
    ((PASS_COUNT++))
}

check_fail() {
    echo "✗ $1"
    echo "  Expected: $2"
    echo "  Got: $3"
    ((FAIL_COUNT++))
}

echo "=== Boot Configuration (cmdline.txt) ==="
CMDLINE=$(ssh "$USER@$PI_IP" "cat /boot/firmware/cmdline.txt")
if echo "$CMDLINE" | grep -q "video=HDMI-A-2:1280x400M@60"; then
    check_pass "Framebuffer resolution correct (1280x400@60)"
else
    check_fail "Framebuffer resolution" "video=HDMI-A-2:1280x400M@60" "$(echo "$CMDLINE" | grep -o 'video=[^ ]*' || echo 'NOT FOUND')"
fi
echo ""

echo "=== Boot Configuration (config.txt) ==="
CONFIG=$(ssh "$USER@$PI_IP" "cat /boot/firmware/config.txt")

if echo "$CONFIG" | grep -q "hdmi_group=2"; then
    check_pass "HDMI group correct (CEA)"
else
    check_fail "HDMI group" "hdmi_group=2" "$(echo "$CONFIG" | grep hdmi_group || echo 'NOT SET')"
fi

if echo "$CONFIG" | grep -q "hdmi_mode=87"; then
    check_pass "HDMI mode correct (custom)"
else
    check_fail "HDMI mode" "hdmi_mode=87" "$(echo "$CONFIG" | grep hdmi_mode || echo 'NOT SET')"
fi

if echo "$CONFIG" | grep -q "hdmi_timings=400 0 220 32 110 1280"; then
    check_pass "HDMI timings correct (1280x400 portrait native)"
else
    check_fail "HDMI timings" "400 0 220 32 110 1280..." "$(echo "$CONFIG" | grep hdmi_timings || echo 'NOT SET')"
fi

if echo "$CONFIG" | grep -q "arm_boost=1"; then
    check_pass "ARM boost enabled"
else
    check_fail "ARM boost" "arm_boost=1" "$(echo "$CONFIG" | grep arm_boost || echo 'NOT SET')"
fi

if echo "$CONFIG" | grep -q "dtparam=audio=off"; then
    check_pass "Onboard audio disabled"
else
    check_fail "Onboard audio" "dtparam=audio=off" "$(echo "$CONFIG" | grep 'dtparam=audio' || echo 'NOT SET')"
fi
echo ""

echo "=== Display Configuration (.xinitrc) ==="
XINITRC=$(ssh "$USER@$PI_IP" "cat ~/.xinitrc 2>/dev/null || echo 'FILE NOT FOUND'")

if echo "$XINITRC" | grep -q "xset -dpms 2>/dev/null || true"; then
    check_pass "DPMS error suppression present (Pi 5 KMS fix)"
else
    check_fail "DPMS error suppression" "xset -dpms 2>/dev/null || true" "$(echo "$XINITRC" | grep 'xset -dpms' || echo 'NOT FOUND')"
fi
echo ""

echo "=== Audio Chain ==="
CARDS=$(ssh "$USER@$PI_IP" "cat /proc/asound/cards 2>/dev/null")

if echo "$CARDS" | grep -q "HiFiBerry"; then
    check_pass "HiFiBerry AMP100 detected"
else
    check_fail "HiFiBerry AMP100" "HiFiBerry in /proc/asound/cards" "$(echo "$CARDS" | head -1 || echo 'NO CARDS')"
fi
echo ""

echo "=== Database Configuration ==="
DB_CHECKS=(
    "local_display:1:Local display enabled"
    "hdmi_scn_orient:portrait:Display orientation"
    "audioout:HiFiBerry AMP100:Audio output device"
)

for check in "${DB_CHECKS[@]}"; do
    IFS=':' read -r param expected description <<< "$check"
    actual=$(ssh "$USER@$PI_IP" "sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT value FROM cfg_system WHERE param='$param'\" 2>/dev/null" || echo "ERROR")
    
    if [ "$actual" = "$expected" ]; then
        check_pass "$description ($param=$expected)"
    else
        check_fail "$description" "$param=$expected" "$param=$actual"
    fi
done
echo ""

echo "=== System Services ==="
SERVICES=("localdisplay" "mpd" "nginx" "php8.4-fpm")

for service in "${SERVICES[@]}"; do
    if ssh "$USER@$PI_IP" "systemctl is-active --quiet $service 2>/dev/null"; then
        check_pass "Service $service is active"
    else
        status=$(ssh "$USER@$PI_IP" "systemctl is-active $service 2>&1" || echo "inactive")
        check_fail "Service $service" "active" "$status"
    fi
done
echo ""

echo "========================================"
echo "Verification Summary"
echo "========================================"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ System matches documented architecture!"
    echo "Reference: WISSENSBASIS/MASTER_MOODE_ARCHITECTURE.md"
    exit 0
else
    echo "⚠️  System does NOT match documented architecture"
    echo "Review failures above and update system or documentation"
    echo "Reference: WISSENSBASIS/MASTER_MOODE_ARCHITECTURE.md"
    exit 1
fi
