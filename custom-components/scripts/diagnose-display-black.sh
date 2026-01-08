#!/bin/bash
################################################################################
#
# DIAGNOSE DISPLAY BLACK SCREEN ISSUE
# 
# Diagnoses why display shows only backlight (black screen) but no content
#
################################################################################

set +e  # Don't exit on error - we want to log everything
LOG_FILE="/var/log/diagnose-display-black.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== DIAGNOSE DISPLAY BLACK SCREEN START ==="

# 1. Check service status
log "1. Checking localdisplay.service status..."
if systemctl is-active localdisplay.service >/dev/null 2>&1; then
    log "   ✅ Service is ACTIVE"
    systemctl status localdisplay.service --no-pager -l | head -30 >> "$LOG_FILE"
else
    log "   ❌ Service is NOT ACTIVE"
    systemctl status localdisplay.service --no-pager -l | head -30 >> "$LOG_FILE"
fi

# 2. Check if Chromium process is running
log "2. Checking Chromium processes..."
CHROMIUM_PROCS=$(ps aux | grep -i chromium | grep -v grep | wc -l)
log "   Chromium processes found: $CHROMIUM_PROCS"
if [ "$CHROMIUM_PROCS" -gt 0 ]; then
    log "   ✅ Chromium is running"
    ps aux | grep -i chromium | grep -v grep >> "$LOG_FILE"
else
    log "   ❌ Chromium is NOT running"
fi

# 3. Check X server
log "3. Checking X server..."
if pgrep -x Xorg >/dev/null 2>&1; then
    log "   ✅ X server is running (PID: $(pgrep -x Xorg))"
else
    log "   ❌ X server is NOT running"
fi

# 4. Check DISPLAY variable
log "4. Checking DISPLAY environment..."
DISPLAY_VAR=$(systemctl show localdisplay.service | grep -i environment || echo "")
log "   DISPLAY env: $DISPLAY_VAR"

# 5. Check .xinitrc file
log "5. Checking .xinitrc configuration..."
USER_ID=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='user_id'" 2>/dev/null || echo "1000")
HOME_DIR=$(getent passwd "$USER_ID" | cut -d: -f6 2>/dev/null || echo "/home/pi")
XINITRC="$HOME_DIR/.xinitrc"
if [ -f "$XINITRC" ]; then
    log "   ✅ .xinitrc exists at: $XINITRC"
    log "   Contents:"
    cat "$XINITRC" >> "$LOG_FILE"
    cat "$XINITRC"
else
    log "   ❌ .xinitrc NOT found at: $XINITRC"
fi

# 6. Check localdisplay.service file
log "6. Checking localdisplay.service configuration..."
SERVICE_FILE="/lib/systemd/system/localdisplay.service"
if [ -f "$SERVICE_FILE" ]; then
    log "   ✅ Service file exists"
    log "   Contents:"
    cat "$SERVICE_FILE" >> "$LOG_FILE"
    cat "$SERVICE_FILE"
else
    log "   ❌ Service file NOT found"
fi

# 7. Check Chromium logs/errors
log "7. Checking recent Chromium/system logs..."
journalctl -u localdisplay.service --since "5 minutes ago" --no-pager -n 50 >> "$LOG_FILE" 2>&1
log "   Recent service logs:"
journalctl -u localdisplay.service --since "5 minutes ago" --no-pager -n 50

# 8. Check if display URL is set
log "8. Checking display URL configuration..."
LOCAL_DISPLAY_URL=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display_url'" 2>/dev/null || echo "")
log "   Display URL: $LOCAL_DISPLAY_URL"

# 9. Try to check if Chromium can access the display
log "9. Checking display accessibility..."
if [ -n "$DISPLAY" ] || [ -f "/tmp/.X0-lock" ]; then
    log "   ✅ Display appears accessible"
else
    log "   ⚠️  Display may not be accessible (DISPLAY not set)"
fi

# 10. Check for any error messages in logs
log "10. Checking for error messages..."
if journalctl -u localdisplay.service --since "1 hour ago" | grep -i "error\|failed\|cannot" >/dev/null 2>&1; then
    log "   ⚠️  Errors found in service logs:"
    journalctl -u localdisplay.service --since "1 hour ago" | grep -i "error\|failed\|cannot" | tail -20 >> "$LOG_FILE"
    journalctl -u localdisplay.service --since "1 hour ago" | grep -i "error\|failed\|cannot" | tail -20
else
    log "   ✅ No obvious errors in recent logs"
fi

log "=== DIAGNOSE DISPLAY BLACK SCREEN END ==="
log ""
log "Full log saved to: $LOG_FILE"
log "To view full log: sudo cat $LOG_FILE"

