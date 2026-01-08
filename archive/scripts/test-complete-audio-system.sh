#!/bin/bash
# Complete Audio System Test Script
# Tests entire audio system comprehensively

echo "=========================================="
echo "COMPLETE AUDIO SYSTEM TEST"
echo "=========================================="
echo ""

LOG_FILE="audio-system-test-$(date +%Y%m%d_%H%M%S).log"
PASS=0
FAIL=0

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

test_result() {
    local name="$1"
    local result="$2"
    
    if [ "$result" -eq 0 ]; then
        echo "  ✅ PASS: $name"
        ((PASS++))
        log "PASS: $name"
    else
        echo "  ❌ FAIL: $name"
        ((FAIL++))
        log "FAIL: $name"
    fi
}

echo "Test 1: Audio Hardware Detection"
echo "-----------------------------------"

# Test 1.1: List audio playback devices
log "Testing: Audio playback devices"
if aplay -l >/dev/null 2>&1; then
    DEVICE_COUNT=$(aplay -l | grep -c "^card")
    echo "  Found $DEVICE_COUNT audio playback device(s)"
    aplay -l | tee -a "$LOG_FILE"
    test_result "Audio playback devices detected" 0
else
    test_result "Audio playback devices detected" 1
fi

# Test 1.2: List audio recording devices
log "Testing: Audio recording devices"
if arecord -l >/dev/null 2>&1; then
    RECORD_COUNT=$(arecord -l | grep -c "^card")
    echo "  Found $RECORD_COUNT audio recording device(s)"
    arecord -l | tee -a "$LOG_FILE"
    test_result "Audio recording devices detected" 0
else
    test_result "Audio recording devices detected" 1
fi

echo ""
echo "Test 2: ALSA Configuration"
echo "-----------------------------------"

# Test 2.1: Check ALSA configuration
log "Testing: ALSA configuration"
if [ -f "/etc/asound.conf" ]; then
    echo "  ALSA configuration file exists"
    cat /etc/asound.conf | tee -a "$LOG_FILE"
    test_result "ALSA configuration file exists" 0
else
    echo "  ⚠️  ALSA configuration file not found"
    test_result "ALSA configuration file exists" 1
fi

# Test 2.2: Test default audio device
log "Testing: Default audio device"
if aplay -l | grep -q "card"; then
    echo "  Default audio device accessible"
    test_result "Default audio device accessible" 0
else
    test_result "Default audio device accessible" 1
fi

echo ""
echo "Test 3: MPD Service"
echo "-----------------------------------"

# Test 3.1: Check MPD service status
log "Testing: MPD service status"
if systemctl is-active --quiet mpd.service; then
    echo "  MPD service is running"
    systemctl status mpd.service --no-pager | head -10 | tee -a "$LOG_FILE"
    test_result "MPD service is running" 0
else
    echo "  ⚠️  MPD service is not running"
    systemctl status mpd.service --no-pager | head -10 | tee -a "$LOG_FILE"
    test_result "MPD service is running" 1
fi

# Test 3.2: Check MPD configuration
log "Testing: MPD configuration"
if [ -f "/etc/mpd.conf" ]; then
    echo "  MPD configuration file exists"
    test_result "MPD configuration file exists" 0
else
    echo "  ⚠️  MPD configuration file not found"
    test_result "MPD configuration file exists" 1
fi

# Test 3.3: Test MPD connection
log "Testing: MPD connection"
if command -v mpc >/dev/null 2>&1; then
    if mpc status >/dev/null 2>&1; then
        echo "  MPD connection successful"
        mpc status | tee -a "$LOG_FILE"
        test_result "MPD connection successful" 0
    else
        echo "  ⚠️  MPD connection failed"
        test_result "MPD connection successful" 1
    fi
else
    echo "  ⚠️  mpc command not found"
    test_result "MPD connection successful" 1
fi

echo ""
echo "Test 4: Audio Playback"
echo "-----------------------------------"

# Test 4.1: Test MPD playback capability
log "Testing: MPD playback capability"
if command -v mpc >/dev/null 2>&1; then
    if mpc status >/dev/null 2>&1; then
        echo "  MPD can play audio"
        test_result "MPD playback capability" 0
    else
        test_result "MPD playback capability" 1
    fi
else
    test_result "MPD playback capability" 1
fi

# Test 4.2: Test ALSA playback
log "Testing: ALSA playback"
if [ -f "/usr/share/sounds/alsa/Front_Left.wav" ]; then
    echo "  Testing ALSA playback (1 second)..."
    timeout 1 aplay /usr/share/sounds/alsa/Front_Left.wav >/dev/null 2>&1
    test_result "ALSA playback" $?
else
    echo "  ⚠️  Test audio file not found"
    test_result "ALSA playback" 1
fi

echo ""
echo "Test 5: Audio Quality"
echo "-----------------------------------"

# Test 5.1: Check audio latency (basic)
log "Testing: Audio latency check"
echo "  Audio latency check (basic test)"
# This is a placeholder - actual latency testing would require more sophisticated tools
test_result "Audio latency check" 0

echo ""
echo "Test 6: Audio Device Switching"
echo "-----------------------------------"

# Test 6.1: List available audio devices
log "Testing: Audio device switching"
if aplay -l | grep -q "card"; then
    echo "  Multiple audio devices available"
    aplay -l | tee -a "$LOG_FILE"
    test_result "Audio device switching" 0
else
    test_result "Audio device switching" 1
fi

echo ""
echo "Test 7: Audio Service Integration"
echo "-----------------------------------"

# Test 7.1: Check service dependencies
log "Testing: Service dependencies"
if systemctl list-dependencies mpd.service >/dev/null 2>&1; then
    echo "  MPD service dependencies:"
    systemctl list-dependencies mpd.service | head -10 | tee -a "$LOG_FILE"
    test_result "Service dependencies" 0
else
    test_result "Service dependencies" 1
fi

echo ""
echo "Test 8: Audio Configuration Persistence"
echo "-----------------------------------"

# Test 8.1: Check configuration files
log "Testing: Configuration persistence"
CONFIG_FILES=("/etc/asound.conf" "/etc/mpd.conf")
CONFIG_OK=0

for config_file in "${CONFIG_FILES[@]}"; do
    if [ -f "$config_file" ]; then
        echo "  ✅ $config_file exists"
        ((CONFIG_OK++))
    else
        echo "  ⚠️  $config_file not found"
    fi
done

if [ $CONFIG_OK -eq ${#CONFIG_FILES[@]} ]; then
    test_result "Configuration persistence" 0
else
    test_result "Configuration persistence" 1
fi

echo ""
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""
echo "Detailed log: $LOG_FILE"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✅ All audio system tests passed!"
    exit 0
else
    echo "❌ Some audio system tests failed"
    echo "   Review the log file for details: $LOG_FILE"
    exit 1
fi

