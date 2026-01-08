#!/bin/bash
################################################################################
#
# FORCE RESTART CHROMIUM
#
# Aggressively kills and restarts Chromium for the local display
# Use this when Chromium is hung or showing black screen
#
################################################################################

LOG_FILE="/var/log/force-restart-chromium.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== FORCE RESTART CHROMIUM START ==="

# 1. Stop service
log "1. Stopping localdisplay service..."
systemctl stop localdisplay.service 2>/dev/null || true
sleep 3

# 2. Aggressively kill all Chromium processes
log "2. Killing all Chromium processes..."
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
killall -9 chromium 2>/dev/null || true
killall -9 chromium-browser 2>/dev/null || true
sleep 2

# 3. Clean up Chromium data directory
log "3. Cleaning Chromium data directory..."
rm -rf /tmp/chromium-data/* 2>/dev/null || true
sleep 1

# 4. Ensure X server is accessible
log "4. Checking X server..."
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
if xset q &>/dev/null; then
    log "   ✅ X server is accessible"
else
    log "   ⚠️  X server may not be ready"
fi

# 5. Start Chromium directly (as a test)
log "5. Starting Chromium directly..."
if [ -f "/usr/local/bin/start-chromium-clean.sh" ]; then
    bash /usr/local/bin/start-chromium-clean.sh >> "$LOG_FILE" 2>&1 &
    CHROMIUM_PID=$!
    sleep 5
    
    if ps -p $CHROMIUM_PID > /dev/null 2>&1; then
        log "   ✅ Chromium started (PID: $CHROMIUM_PID)"
    else
        log "   ❌ Chromium failed to start"
    fi
else
    log "   ❌ start-chromium-clean.sh not found"
fi

# 6. Start service
log "6. Starting localdisplay service..."
systemctl daemon-reload
systemctl start localdisplay.service
sleep 5

# 7. Verify
if systemctl is-active localdisplay.service >/dev/null 2>&1; then
    log "   ✅ Service is active"
else
    log "   ❌ Service is not active"
fi

CHROMIUM_COUNT=$(ps aux | grep -i chromium | grep -v grep | wc -l)
if [ "$CHROMIUM_COUNT" -gt 0 ]; then
    log "   ✅ Chromium is running ($CHROMIUM_COUNT processes)"
else
    log "   ❌ Chromium is not running"
fi

log "=== FORCE RESTART CHROMIUM END ==="

