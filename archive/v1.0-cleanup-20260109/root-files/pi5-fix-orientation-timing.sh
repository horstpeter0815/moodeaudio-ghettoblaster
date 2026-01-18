#!/bin/bash
# PI 5 FIX: Orientation & Timing Issues
# Fix display rotation and optimize timing

set -e

echo "=========================================="
echo "PI 5 ORIENTATION & TIMING FIX"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== STEP 1: BACKUP CURRENT .xinitrc ==="
ssh pi2 << 'BACKUP'
BACKUP_DIR="/home/andre/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp /home/andre/.xinitrc "$BACKUP_DIR/.xinitrc.backup"
echo "✅ Backup created: $BACKUP_DIR"
BACKUP

echo ""
echo "=== STEP 2: CREATE OPTIMIZED .xinitrc WITH ROTATION ==="
ssh pi2 << 'XINITRC'
cat > /tmp/.xinitrc_fixed << 'EOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X server to be fully ready
# Reduced from 3s, but ensure X is ready
MAX_X_WAIT=10
X_WAITED=0
while [ $X_WAITED -lt $MAX_X_WAIT ]; do
    if xrandr --query >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
    X_WAITED=$((X_WAITED + 1))
done

# CRITICAL FOR PI 5: Allow user andre to access X server (running as root)
xhost +SI:localuser:andre 2>/dev/null || true

# Set up display resolution with ROTATION
# For 1280x400 landscape, we need left rotation
xrandr --newmode "1280x400_60.00" 27.00 1280 1328 1456 1632 400 403 413 421 -hsync +vsync 2>&1
xrandr --addmode HDMI-2 "1280x400_60.00" 2>&1

# Apply resolution WITH ROTATION (left = landscape 1280x400)
xrandr --output HDMI-2 --mode "1280x400_60.00" --rotate left 2>&1

# Wait for rotation to apply
sleep 1

# Disable screen blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium in background so we can fix window after start
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

# Wait for Chromium to initialize (optimized timing)
# Start checking earlier, but wait longer if needed
sleep 5

# Fix window size and orientation
MAX_ATTEMPTS=5
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    WINDOW=$(xdotool search --class Chromium --name "Player" 2>/dev/null | head -1)
    
    if [ -z "$WINDOW" ]; then
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    fi
    
    if [ -n "$WINDOW" ]; then
        # Get current geometry
        CURRENT=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        
        # Resize to correct size
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        
        # Verify
        NEW=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        
        if [ "$NEW" == "1280x400" ]; then
            echo "✅ Window resized to 1280x400" >> /tmp/xinit.log
            break
        fi
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    sleep 2
done

# Keep this process alive (Chromium will be child)
wait $CHROMIUM_PID
EOF

sudo cp /tmp/.xinitrc_fixed /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ Optimized .xinitrc created with rotation"
cat /home/andre/.xinitrc
XINITRC

echo ""
echo "=== STEP 3: CHECK/UPDATE WINDOW FIX SCRIPT ==="
ssh pi2 << 'WINDOWFIX'
cat > /tmp/fix-window-size.sh << 'EOF'
#!/bin/bash
# Auto-resize Chromium window with proper orientation check
export DISPLAY=:0

MAX_ATTEMPTS=10
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    # Find main Chromium window
    WINDOW=$(xdotool search --class Chromium --name "Player" 2>/dev/null | head -1)
    
    if [ -z "$WINDOW" ]; then
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    fi
    
    if [ -n "$WINDOW" ]; then
        # Resize to correct size
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        sleep 0.5
        
        # Verify
        NEW=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        
        if [ "$NEW" == "1280x400" ]; then
            echo "✅ Window: 1280x400" >> /tmp/window-fix.log
            exit 0
        fi
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    sleep 1
done

echo "⚠️ Window resize incomplete" >> /tmp/window-fix.log
EOF

sudo cp /tmp/fix-window-size.sh /usr/local/bin/fix-window-size.sh
sudo chmod +x /usr/local/bin/fix-window-size.sh
echo "✅ Window fix script updated"
WINDOWFIX

echo ""
echo "=== STEP 4: RESTART AND VERIFY ==="
ssh pi2 << 'RESTART'
echo "Stopping localdisplay service..."
sudo systemctl stop localdisplay
sleep 2

echo "Killing all processes..."
sudo pkill -9 chromium Xorg xinit 2>/dev/null || true
sleep 2

echo "Starting localdisplay service..."
sudo systemctl start localdisplay

echo "Waiting for system to stabilize (20 seconds)..."
sleep 20
RESTART

echo ""
echo "=== STEP 5: VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "1. Display rotation:"
xrandr --query | grep "HDMI-2" | grep -E "rotate|normal"

echo ""
echo "2. Display resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "3. Chromium processes:"
ps aux | grep chromium | grep -v grep | wc -l

echo ""
echo "4. Window check:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -2

echo ""
echo "5. Window size verification:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry || echo "Could not get geometry"
fi
VERIFY

echo ""
echo "=========================================="
echo "FIX COMPLETE"
echo "=========================================="
echo ""
echo "Please check the display orientation visually!"
echo "Expected: Landscape (1280x400) rotated left"

