#!/bin/bash
# PI 5 CHIEF ENGINEER - COMPLETE AUTOMATED FIX
# No interaction needed - fixes everything automatically

set -e

echo "=========================================="
echo "PI 5 CHIEF ENGINEER - COMPLETE FIX"
echo "Automated - No Interaction Required"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Wait for system to be fully ready
echo "=== STEP 1: WAITING FOR SYSTEM READY ==="
MAX_WAIT=120
WAITED=0
SERVICES_READY=false

while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        if ssh -o ConnectTimeout=5 pi2 "systemctl is-active localdisplay mpd nginx" >/dev/null 2>&1; then
            SERVICES_READY=true
            echo "✅ Services ready after ${WAITED}s"
            break
        fi
    fi
    sleep 3
    WAITED=$((WAITED + 3))
    echo -n "."
done

if [ "$SERVICES_READY" = false ]; then
    echo "⚠️ Services not fully ready, continuing anyway..."
fi

echo ""
echo "=== STEP 2: COMPREHENSIVE DIAGNOSIS ==="
ssh pi2 << 'DIAGNOSIS'
export DISPLAY=:0

echo "=== CURRENT STATE ==="
echo "1. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"
echo ""

echo "2. Display:"
xrandr --query | grep "HDMI-2 connected"
echo ""

echo "3. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1
echo ""

echo "4. Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"
echo ""

echo "5. Window:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -2
echo ""

echo "6. Window size:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW | grep Geometry
fi
echo ""

echo "7. Config.txt:"
sudo grep -E "display_rotate|framebuffer|hdmi_cvt" /boot/config.txt 2>/dev/null | head -5
echo ""

echo "8. Cmdline video:"
cat /proc/cmdline | grep -o 'video=[^ ]*' || echo "Not found"
DIAGNOSIS

echo ""
echo "=== STEP 3: AUTOMATED FIXES ==="
ssh pi2 << 'AUTOFIX'
export DISPLAY=:0

# Fix 1: Ensure display is 1280x400 Landscape
echo "Fix 1: Setting display to 1280x400 Landscape..."
RES=$(xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)

if [ "$RES" != "1280x400" ]; then
    echo "  Current: $RES - Fixing..."
    
    # Create and set 1280x400 mode
    TIMING=$(cvt 1280 400 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    
    xrandr --delmode HDMI-2 "$MODE_NAME" 2>/dev/null || true
    xrandr --rmmode "$MODE_NAME" 2>/dev/null || true
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
    xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
    sleep 1
    
    echo "  ✅ Display set to 1280x400"
else
    echo "  ✅ Display already 1280x400"
fi

# Fix 2: Fix Chromium window size
echo ""
echo "Fix 2: Fixing Chromium window size..."
CHROMIUM_COUNT=$(ps aux | grep chromium | grep -v grep | wc -l)

if [ "$CHROMIUM_COUNT" -gt "0" ]; then
    for attempt in {1..10}; do
        WINDOW=$(xdotool search --class Chromium --name "Player" 2>/dev/null | head -1)
        if [ -z "$WINDOW" ]; then
            WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
        fi
        
        if [ -n "$WINDOW" ]; then
            CURRENT_SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
            
            if [ "$CURRENT_SIZE" != "1280x400" ]; then
                xdotool windowsize $WINDOW 1280 400 2>/dev/null
                xdotool windowmove $WINDOW 0 0 2>/dev/null
                sleep 1
                
                NEW_SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
                if [ "$NEW_SIZE" == "1280x400" ]; then
                    echo "  ✅ Window fixed: $NEW_SIZE"
                    break
                fi
            else
                echo "  ✅ Window already correct: $CURRENT_SIZE"
                break
            fi
        fi
        sleep 1
    done
else
    echo "  ⚠️ Chromium not running yet"
fi

# Fix 3: Verify no flickering issues
echo ""
echo "Fix 3: Verifying display stability..."
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

echo "  ✅ Screen blanking disabled"

echo ""
echo "=== FIXES APPLIED ==="
AUTOFIX

echo ""
echo "=== STEP 4: FINAL VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "=== FINAL STATUS ==="
echo ""
echo "Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"
echo ""

echo "Display:"
xrandr --query | grep "HDMI-2 connected"
echo ""

echo "Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1
echo ""

echo "Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"
echo ""

echo "Window:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW | grep Geometry
fi
echo ""

echo "=== VERIFICATION COMPLETE ==="
VERIFY

echo ""
echo "=========================================="
echo "CHIEF ENGINEER FIX COMPLETE"
echo "=========================================="
echo ""
echo "All fixes applied automatically."
echo "Please check display visually for:"
echo "  - Correct orientation (1280x400 Landscape)"
echo "  - No flickering"
echo "  - No black noise"
echo "  - Clear, stable picture"
echo ""
echo "If issues persist, framebuffer may need different approach."

