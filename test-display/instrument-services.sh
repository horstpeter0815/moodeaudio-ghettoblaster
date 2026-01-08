#!/bin/bash
################################################################################
#
# SERVICE STARTUP INSTRUMENTATION
#
# Hooks into systemd services:
# - xserver-ready.service → log X11 readiness
# - localdisplay.service → log service start
# - .xinitrc execution → log each step
# - Chromium launch → log process creation
#
################################################################################

set -e

# Source the logger
source /scripts/display-chain-logger.sh 2>/dev/null || {
    LOG_FILE="/var/log/display-chain/services.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    log() {
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" >> "$LOG_FILE"
    }
}

log_service() {
    log "[SERVICES] $*"
}

# Monitor xserver-ready.service
if systemctl is-active xserver-ready.service >/dev/null 2>&1 || systemctl is-enabled xserver-ready.service >/dev/null 2>&1; then
    log_service "xserver-ready.service detected"
    systemctl status xserver-ready.service --no-pager -l | head -20 >> "$LOG_FILE" 2>&1 || true
fi

# Check X11 readiness
if command -v xrandr >/dev/null 2>&1; then
    if DISPLAY=:0 xrandr --query >/dev/null 2>&1; then
        X11_INFO=$(DISPLAY=:0 xrandr --query | grep " connected" | head -1 || echo "")
        log_service "X11 server ready: $X11_INFO"
    else
        log_service "X11 server not ready yet"
    fi
fi

# Monitor localdisplay.service
if systemctl is-active localdisplay.service >/dev/null 2>&1 || systemctl is-enabled localdisplay.service >/dev/null 2>&1; then
    log_service "localdisplay.service detected"
    systemctl status localdisplay.service --no-pager -l | head -30 >> "$LOG_FILE" 2>&1 || true
fi

# Check .xinitrc execution
USER_ID=$(id -u 2>/dev/null || echo "1000")
HOME_DIR=$(getent passwd "$USER_ID" | cut -d: -f6 2>/dev/null || echo "/home/test")
XINITRC="$HOME_DIR/.xinitrc"

if [ -f "$XINITRC" ]; then
    log_service ".xinitrc found at: $XINITRC"
    # Check if it's currently executing
    if pgrep -f ".xinitrc" >/dev/null 2>&1; then
        log_service ".xinitrc is executing"
    fi
else
    log_service ".xinitrc not found at: $XINITRC"
fi

# Monitor Chromium processes
CHROMIUM_PROCS=$(pgrep -f chromium 2>/dev/null | wc -l || echo "0")
if [ "$CHROMIUM_PROCS" -gt 0 ]; then
    log_service "Chromium processes detected: $CHROMIUM_PROCS"
    ps aux | grep -i chromium | grep -v grep | head -5 >> "$LOG_FILE" 2>&1 || true
    
    # Try to get window info
    if command -v xwininfo >/dev/null 2>&1 && DISPLAY=:0 xwininfo -root -tree >/dev/null 2>&1; then
        CHROMIUM_WINDOW=$(DISPLAY=:0 xwininfo -root -tree 2>&1 | grep -i chromium | head -1 || echo "")
        if [ -n "$CHROMIUM_WINDOW" ]; then
            log_service "Chromium window detected: $CHROMIUM_WINDOW"
        fi
    fi
else
    log_service "No Chromium processes detected"
fi

log_service "Service instrumentation complete"

