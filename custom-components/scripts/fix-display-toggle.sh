#!/bin/bash
################################################################################
#
# FIX DISPLAY TOGGLE ISSUE
# 
# Diagnoses and fixes display not turning back on after being toggled off
#
################################################################################

set -e

LOG_FILE="/var/log/fix-display-toggle.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== FIX DISPLAY TOGGLE START ==="

# 1. Check database setting
log "1. Checking database setting..."
LOCAL_DISPLAY_DB=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'" 2>/dev/null || echo "")
log "   Database value: $LOCAL_DISPLAY_DB"

# 2. Check service status
log "2. Checking service status..."
if systemctl is-active localdisplay.service >/dev/null 2>&1; then
    log "   Service is ACTIVE"
    SERVICE_STATE="active"
elif systemctl is-enabled localdisplay.service >/dev/null 2>&1; then
    log "   Service is ENABLED but not active"
    SERVICE_STATE="enabled"
    log "   Attempting to start service..."
    systemctl start localdisplay.service || {
        log "   ❌ Failed to start service, checking status..."
        systemctl status localdisplay.service --no-pager -l | tail -20
    }
else
    log "   Service is NOT ENABLED"
    SERVICE_STATE="disabled"
fi

# 3. Check if service exists
if [ ! -f "/lib/systemd/system/localdisplay.service" ]; then
    log "   ⚠️  Service file missing - running auto-fix-display.sh..."
    /usr/local/bin/auto-fix-display.sh
fi

# 4. If database says ON but service is not running, start it
if [ "$LOCAL_DISPLAY_DB" = "1" ] && [ "$SERVICE_STATE" != "active" ]; then
    log "3. Database says ON but service not active - starting service..."
    systemctl daemon-reload
    systemctl enable localdisplay.service 2>/dev/null || true
    systemctl start localdisplay.service || {
        log "   ❌ Failed to start - checking logs..."
        journalctl -u localdisplay.service --no-pager -n 30
    }
fi

# 5. If database says OFF, ensure service is stopped (sync state)
if [ "$LOCAL_DISPLAY_DB" = "0" ]; then
    if [ "$SERVICE_STATE" = "active" ]; then
        log "4. Database says OFF but service is active - stopping service..."
        systemctl stop localdisplay.service 2>/dev/null || true
        log "   ✅ Service stopped to match database state"
    else
        log "4. Database says OFF and service is not active - state is correct"
    fi
fi

# 6. Final status check
sleep 2
if systemctl is-active localdisplay.service >/dev/null 2>&1; then
    log "✅ Service is now ACTIVE"
    log "✅ Display should be working"
else
    log "❌ Service is still not active"
    log "   Checking service status..."
    systemctl status localdisplay.service --no-pager -l | tail -30
    log "   ⚠️  Manual intervention may be required"
fi

log "=== FIX DISPLAY TOGGLE END ==="

