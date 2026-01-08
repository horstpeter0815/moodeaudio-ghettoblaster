#!/bin/bash
# PI 5 COMPLETE FIX - Senior Project Manager Implementation
# Goal: Perfect Pi 5 system with persistent fixes

set -e

echo "=========================================="
echo "PI 5 COMPLETE FIX"
echo "Raspberry Pi 5 Model B - moOde Audio"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== STEP 1: BACKUP CURRENT CONFIGURATION ==="
ssh pi2 << 'BACKUP'
echo "Creating backups..."
BACKUP_DIR="/home/andre/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup .xinitrc
cp /home/andre/.xinitrc "$BACKUP_DIR/.xinitrc.backup" 2>/dev/null || true

# Backup service override
mkdir -p "$BACKUP_DIR/service"
cp -r /etc/systemd/system/localdisplay.service.d "$BACKUP_DIR/service/" 2>/dev/null || true

echo "✅ Backups created in: $BACKUP_DIR"
BACKUP

echo ""
echo "=== STEP 2: CREATE PERFECT .xinitrc ==="
ssh pi2 << 'XINITRC'
cat > /tmp/.xinitrc_perfect << 'EOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X server to be ready
sleep 3

# CRITICAL FOR PI 5: Allow user andre to access X server (running as root)
xhost +SI:localuser:andre 2>/dev/null || true

# Set up display resolution and rotation
xrandr --newmode "1280x400_60.00" 27.00 1280 1328 1456 1632 400 403 413 421 -hsync +vsync 2>&1
xrandr --addmode HDMI-2 "1280x400_60.00" 2>&1
xrandr --output HDMI-2 --mode "1280x400_60.00" 2>&1

# Disable screen blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium in TRUE kiosk mode with Pi 5 specific flags
exec chromium-browser \
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
    http://localhost 2>&1
EOF

sudo cp /tmp/.xinitrc_perfect /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ Perfect .xinitrc created"
cat /home/andre/.xinitrc
XINITRC

echo ""
echo "=== STEP 3: CREATE WINDOW SIZE FIX SCRIPT ==="
ssh pi2 << 'WINDOWFIX'
cat > /tmp/fix-window-size.sh << 'EOF'
#!/bin/bash
# Auto-resize Chromium window to correct size
# Called after Chromium starts

export DISPLAY=:0
sleep 5  # Wait for Chromium to fully initialize

MAX_ATTEMPTS=10
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    # Find main Chromium window
    WINDOW=$(xdotool search --class Chromium --name "Player" 2>/dev/null | head -1)
    
    if [ -z "$WINDOW" ]; then
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    fi
    
    if [ -n "$WINDOW" ]; then
        # Get current geometry
        CURRENT=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}')
        
        # Resize to correct size
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        sleep 1
        
        # Verify
        NEW=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}')
        
        if [ "$NEW" == "1280x400" ]; then
            echo "✅ Window resized to 1280x400"
            exit 0
        fi
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    sleep 2
done

echo "⚠️ Could not resize window after $MAX_ATTEMPTS attempts"
EOF

sudo cp /tmp/fix-window-size.sh /usr/local/bin/fix-window-size.sh
sudo chmod +x /usr/local/bin/fix-window-size.sh
echo "✅ Window fix script created"
WINDOWFIX

echo ""
echo "=== STEP 4: UPDATE .xinitrc TO AUTO-FIX WINDOW ==="
ssh pi2 << 'AUTOFIX'
# Update .xinitrc to automatically fix window size after Chromium starts
cat > /tmp/.xinitrc_with_autofix << 'EOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X server to be ready
sleep 3

# CRITICAL FOR PI 5: Allow user andre to access X server (running as root)
xhost +SI:localuser:andre 2>/dev/null || true

# Set up display resolution and rotation
xrandr --newmode "1280x400_60.00" 27.00 1280 1328 1456 1632 400 403 413 421 -hsync +vsync 2>&1
xrandr --addmode HDMI-2 "1280x400_60.00" 2>&1
xrandr --output HDMI-2 --mode "1280x400_60.00" 2>&1

# Disable screen blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium in background so we can fix window size
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
    http://localhost >/dev/null 2>&1 &

CHROMIUM_PID=$!

# Wait for Chromium to start, then fix window size
sleep 8
/usr/local/bin/fix-window-size.sh

# Keep this process alive (Chromium will be child)
wait $CHROMIUM_PID
EOF

sudo cp /tmp/.xinitrc_with_autofix /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ .xinitrc updated with auto-fix"
AUTOFIX

echo ""
echo "=== STEP 5: RESTART AND VERIFY ==="
ssh pi2 << 'RESTART'
echo "Stopping localdisplay service..."
sudo systemctl stop localdisplay
sleep 2

echo "Killing all processes..."
sudo pkill -9 chromium Xorg xinit 2>/dev/null || true
sleep 2

echo "Starting localdisplay service..."
sudo systemctl start localdisplay

echo "Waiting for system to stabilize..."
sleep 20
RESTART

echo ""
echo "=== STEP 6: VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "1. Chromium processes:"
ps aux | grep chromium | grep -v grep | wc -l

echo ""
echo "2. Window check:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -3

echo ""
echo "3. Window size verification:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry
fi

echo ""
echo "4. Display resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1
VERIFY

echo ""
echo "=========================================="
echo "PI 5 FIX COMPLETE"
echo "=========================================="
echo ""
echo "Next: Test boot sequence 3x per project plan"

