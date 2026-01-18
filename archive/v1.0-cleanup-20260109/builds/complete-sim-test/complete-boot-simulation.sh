#!/bin/bash
################################################################################
#
# COMPLETE BOOT SIMULATION - Display, Audio, Services
#
# Simulates the complete Pi boot process including:
# - Network initialization
# - User creation/verification
# - SSH activation
# - Display initialization (X Server)
# - Audio initialization (ALSA)
# - Chromium startup
#
################################################################################

LOG_FILE="/var/log/sim/complete-boot-simulation.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "╔══════════════════════════════════════════════════════════════╗"
log "║  🚀 COMPLETE BOOT SIMULATION START                           ║"
log "╚══════════════════════════════════════════════════════════════╝"

# ============================================================================
# PHASE 1: EARLY BOOT - Network, User, SSH
# ============================================================================
log ""
log "=== PHASE 1: EARLY BOOT ==="

# 1.1: Enable SSH Early
log "1.1: Starting enable-ssh-early.service..."
systemctl start enable-ssh-early.service 2>&1 | tee -a "$LOG_FILE" || log "⚠️  enable-ssh-early.service failed"
sleep 2

# 1.2: Verify User
log "1.2: Verifying user 'andre'..."
if id -u andre >/dev/null 2>&1; then
    UID=$(id -u andre)
    GID=$(id -g andre)
    if [ "$UID" = "1000" ] && [ "$GID" = "1000" ]; then
        log "✅ User 'andre' has correct UID/GID 1000:1000"
    else
        log "❌ User 'andre' has wrong UID/GID: $UID:$GID (should be 1000:1000)"
        log "1.3: Starting fix-user-id.service..."
        systemctl start fix-user-id.service 2>&1 | tee -a "$LOG_FILE" || log "⚠️  fix-user-id.service failed"
    fi
else
    log "❌ User 'andre' does not exist"
    exit 1
fi
sleep 2

# 1.4: Fix SSH and Sudoers (after moOde startup simulation)
log "1.4: Starting fix-ssh-sudoers.service..."
systemctl start fix-ssh-sudoers.service 2>&1 | tee -a "$LOG_FILE" || log "⚠️  fix-ssh-sudoers.service failed"
sleep 2

# ============================================================================
# PHASE 2: DISPLAY INITIALIZATION
# ============================================================================
log ""
log "=== PHASE 2: DISPLAY INITIALIZATION ==="

# 2.1: Disable Console
log "2.1: Starting disable-console.service..."
systemctl start disable-console.service 2>&1 | tee -a "$LOG_FILE" || log "⚠️  disable-console.service failed"
sleep 2

# 2.2: Start X Server (simulated with Xvfb)
log "2.2: Starting X Server (Xvfb)..."
export DISPLAY=:0
Xvfb :0 -screen 0 1280x400x24 -ac +extension GLX +render -noreset >/var/log/sim/xvfb.log 2>&1 &
XVFB_PID=$!
sleep 3
if ps -p $XVFB_PID > /dev/null 2>&1; then
    log "✅ X Server (Xvfb) started (PID: $XVFB_PID)"
else
    log "❌ X Server (Xvfb) failed to start"
    exit 1
fi

# 2.3: Wait for X Server Ready
log "2.3: Waiting for X Server ready..."
if [ -f "/usr/local/bin/custom/xserver-ready.sh" ]; then
    /usr/local/bin/custom/xserver-ready.sh 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        log "✅ X Server ready"
    else
        log "❌ X Server not ready"
        exit 1
    fi
else
    log "⚠️  xserver-ready.sh not found"
    sleep 2
fi

# 2.4: Configure Display (xrandr simulation)
log "2.4: Configuring display (xrandr)..."
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
xhost +SI:localuser:andre 2>/dev/null || true

# Simulate xrandr output for 1280x400
if command -v xrandr >/dev/null 2>&1; then
    # In simulation, we can't actually set resolution, but we can test the command
    log "✅ xrandr available (simulated)"
else
    log "⚠️  xrandr not available"
fi

# ============================================================================
# PHASE 3: AUDIO INITIALIZATION
# ============================================================================
log ""
log "=== PHASE 3: AUDIO INITIALIZATION ==="

# 3.1: Check ALSA
log "3.1: Checking ALSA..."
if command -v alsamixer >/dev/null 2>&1; then
    log "✅ ALSA tools available"
    # List audio devices (simulated)
    if [ -f "/proc/asound/cards" ]; then
        log "✅ ALSA cards detected:"
        cat /proc/asound/cards 2>/dev/null | tee -a "$LOG_FILE" || log "⚠️  No ALSA cards"
    else
        log "⚠️  /proc/asound/cards not available (normal in Docker)"
    fi
else
    log "⚠️  ALSA tools not available"
fi

# 3.2: Check Audio Services
log "3.2: Checking audio services..."
if [ -f "/lib/systemd/system/custom/audio-optimize.service" ]; then
    log "✅ audio-optimize.service found"
    # In real Pi, this would configure audio
    log "✅ Audio optimization service available"
else
    log "⚠️  audio-optimize.service not found"
fi

# ============================================================================
# PHASE 4: CHROMIUM STARTUP
# ============================================================================
log ""
log "=== PHASE 4: CHROMIUM STARTUP ==="

# 4.1: Start Chromium (simulated)
log "4.1: Starting Chromium..."
if [ -f "/usr/local/bin/custom/start-chromium-clean.sh" ]; then
    export DISPLAY=:0
    export XAUTHORITY=/home/andre/.Xauthority
    
    # Test script syntax
    bash -n /usr/local/bin/custom/start-chromium-clean.sh
    if [ $? -eq 0 ]; then
        log "✅ start-chromium-clean.sh syntax OK"
        
        # In real Pi, Chromium would start here
        # In simulation, we just verify the script is correct
        if grep -q "\\--kiosk" /usr/local/bin/custom/start-chromium-clean.sh; then
            log "✅ Chromium script has --kiosk flag"
        else
            log "❌ Chromium script missing --kiosk flag"
        fi
        
        if grep -q "display_rotate=0\|xrandr.*rotate.*normal" /usr/local/bin/custom/start-chromium-clean.sh; then
            log "✅ Chromium script has display rotation fix"
        else
            log "⚠️  Chromium script may not handle display rotation"
        fi
    else
        log "❌ start-chromium-clean.sh has syntax errors"
    fi
else
    log "❌ start-chromium-clean.sh not found"
fi

# 4.2: Start Local Display Service
log "4.2: Starting localdisplay.service..."
systemctl start localdisplay.service 2>&1 | tee -a "$LOG_FILE" || log "⚠️  localdisplay.service failed"
sleep 3

# ============================================================================
# PHASE 5: FINAL VERIFICATION
# ============================================================================
log ""
log "=== PHASE 5: FINAL VERIFICATION ==="

# 5.1: Check all services
log "5.1: Checking all services..."
SERVICES=(
    "enable-ssh-early.service"
    "fix-ssh-sudoers.service"
    "fix-user-id.service"
    "disable-console.service"
    "localdisplay.service"
)

for service in "${SERVICES[@]}"; do
    if systemctl is-active "$service" >/dev/null 2>&1; then
        log "✅ $service is active"
    else
        log "⚠️  $service is not active"
    fi
done

# 5.2: Check network
log "5.2: Checking network..."
if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
    log "✅ Network connectivity OK"
else
    log "⚠️  Network connectivity not available (normal in Docker)"
fi

# 5.3: Check SSH
log "5.3: Checking SSH..."
if systemctl is-active ssh >/dev/null 2>&1; then
    log "✅ SSH is active"
else
    log "⚠️  SSH is not active"
fi

# 5.4: Check Display
log "5.4: Checking Display..."
if [ -n "$DISPLAY" ] && ps -p $XVFB_PID > /dev/null 2>&1; then
    log "✅ Display (X Server) is running"
else
    log "❌ Display (X Server) is not running"
fi

log ""
log "╔══════════════════════════════════════════════════════════════╗"
log "║  ✅ COMPLETE BOOT SIMULATION END                             ║"
log "╚══════════════════════════════════════════════════════════════╝"

exit 0

