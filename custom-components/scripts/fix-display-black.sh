#!/bin/bash
################################################################################
#
# FIX DISPLAY BLACK SCREEN ISSUE
# 
# Fixes display showing only backlight (black screen) by restarting Chromium properly
#
################################################################################

set +e  # Don't exit on error - we want to log everything

LOG_FILE="/var/log/fix-display-black.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== FIX DISPLAY BLACK SCREEN START ==="

# 1. Get user and home directory
USER_ID=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='user_id'" 2>/dev/null || echo "1000")
HOME_DIR=$(getent passwd "$USER_ID" | cut -d: -f6 2>/dev/null || echo "/home/pi")
log "User ID: $USER_ID, Home: $HOME_DIR"

# 2. Get display URL
LOCAL_DISPLAY_URL=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display_url'" 2>/dev/null || echo "http://localhost")
log "Display URL: $LOCAL_DISPLAY_URL"

# 3. Stop localdisplay service
log "1. Stopping localdisplay service..."
systemctl stop localdisplay.service 2>/dev/null || true
sleep 2

# 4. Kill any remaining Chromium processes
log "2. Killing any remaining Chromium processes..."
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 2

# 5. Ensure start-chromium-clean.sh exists and is executable
log "3. Checking start-chromium-clean.sh..."
CHROMIUM_SCRIPT="/usr/local/bin/start-chromium-clean.sh"
if [ ! -f "$CHROMIUM_SCRIPT" ]; then
    log "   ⚠️  start-chromium-clean.sh missing, running auto-fix-display.sh..."
    /usr/local/bin/auto-fix-display.sh 2>/dev/null || true
fi
if [ -f "$CHROMIUM_SCRIPT" ]; then
    chmod +x "$CHROMIUM_SCRIPT" 2>/dev/null || true
    log "   ✅ start-chromium-clean.sh exists and is executable"
else
    log "   ❌ start-chromium-clean.sh still missing after auto-fix"
fi

# 6. Ensure service file exists and is correct
log "4. Checking service file..."
SERVICE_FILE="/lib/systemd/system/localdisplay.service"
if [ ! -f "$SERVICE_FILE" ]; then
    log "   Service file missing, running auto-fix-display.sh..."
    /usr/local/bin/auto-fix-display.sh 2>/dev/null || true
fi

# 7. Ensure service is enabled
log "5. Enabling service..."
systemctl daemon-reload
systemctl enable localdisplay.service 2>/dev/null || true

# 8. Start the service
log "6. Starting localdisplay service..."
if ! systemctl start localdisplay.service; then
    log "   ❌ Failed to start service"
    systemctl status localdisplay.service --no-pager -l | tail -30 >> "$LOG_FILE"
    log "   Attempting force restart..."
    if [ -f "/usr/local/bin/force-restart-chromium.sh" ]; then
        bash /usr/local/bin/force-restart-chromium.sh
    fi
fi

# 9. Wait a moment and check status
sleep 5
if systemctl is-active localdisplay.service >/dev/null 2>&1; then
    log "   ✅ Service started successfully"
else
    log "   ❌ Service not active after start"
    systemctl status localdisplay.service --no-pager -l | tail -30
fi

# 10. Check if Chromium is running
sleep 3
CHROMIUM_COUNT=$(ps aux | grep -i chromium | grep -v grep | wc -l)
if [ "$CHROMIUM_COUNT" -gt 0 ]; then
    log "   ✅ Chromium is running ($CHROMIUM_COUNT processes)"
else
    log "   ⚠️  Chromium may not be running yet (check logs)"
fi

log "=== FIX DISPLAY BLACK SCREEN END ==="
log ""
log "If display is still black, check logs:"
log "  sudo journalctl -u localdisplay.service -n 50"
log "  sudo cat $LOG_FILE"

