#!/bin/bash
# Ghettoblaster - Clean Chromium Startup
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
LOG_FILE=/var/log/chromium-clean.log
log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}
log "=== CHROMIUM CLEAN START ==="

# Display chain logging
CHAIN_LOG="/var/log/display-chain/chromium.log"
mkdir -p "$(dirname "$CHAIN_LOG")"
log_chain() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S.%N)] [CHROMIUM] $*" | tee -a "$CHAIN_LOG"
}

/usr/local/bin/xserver-ready.sh || exit 1
log "✅ X Server bereit"

# Log X11 state before xrandr
X11_BEFORE=$(xrandr --query 2>/dev/null | grep " connected" | head -1 || echo "")
log_chain "X11 state before xrandr: $X11_BEFORE"
xhost +SI:localuser:andre 2>/dev/null || true
sleep 1
if xrandr | grep -q "400x1280"; then
    log_chain "Applying xrandr: mode=400x1280, rotation=left"
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1 | tee -a "$CHAIN_LOG" || \
    xrandr --output HDMI-1 --mode 400x1280 --rotate left 2>&1 | tee -a "$CHAIN_LOG"
elif xrandr | grep -q "1280x400"; then
    log_chain "Applying xrandr: mode=1280x400, rotation=normal"
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1 | tee -a "$CHAIN_LOG" || \
    xrandr --output HDMI-1 --mode 1280x400 --rotate normal 2>&1 | tee -a "$CHAIN_LOG"
fi

# Log X11 state after xrandr
X11_AFTER=$(xrandr --query 2>/dev/null | grep " connected" | head -1 || echo "")
log_chain "X11 state after xrandr: $X11_AFTER"
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 2
rm -rf /tmp/chromium-data/Singleton* 2>/dev/null || true
log "Starte Chromium..."
log_chain "Launching Chromium with window-size=1280,400"

chromium-browser \
    --kiosk \
    --no-sandbox \
    --user-data-dir=/tmp/chromium-data \
    --window-size=1280,400 \
    --window-position=0,0 \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --autoplay-policy=no-user-gesture-required \
    --check-for-update-interval=31536000 \
    --disable-features=TranslateUI \
    --disable-gpu \
    --disable-software-rasterizer \
    http://localhost >/dev/null 2>&1 &
CHROMIUM_PID=$!
log_chain "Chromium PID: $CHROMIUM_PID"

sleep 3
if ps -p $CHROMIUM_PID > /dev/null 2>&1; then
    log "✅ Chromium gestartet (PID: $CHROMIUM_PID)"
    log_chain "Chromium process started successfully"
    for i in {1..10}; do
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
        if [ -n "$WINDOW" ]; then
            WINDOW_SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
            log_chain "Chromium window found: ID=$WINDOW, Size=$WINDOW_SIZE"
            xdotool windowsize $WINDOW 1280 400 2>/dev/null
            xdotool windowmove $WINDOW 0 0 2>/dev/null
            xdotool windowraise $WINDOW 2>/dev/null
            FINAL_SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
            log_chain "Chromium window resized: Final size=$FINAL_SIZE"
            log "✅ Chromium Window gefunden"
            exit 0
        fi
        sleep 1
    done
    log "⚠️  Chromium läuft, aber Window nicht gefunden"
    log_chain "Chromium running but window not found"
    exit 0
else
    log "❌ Chromium Start fehlgeschlagen"
    log_chain "Chromium start failed"
    exit 1
fi
