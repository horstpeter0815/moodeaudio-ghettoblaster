#!/bin/bash
# COMPREHENSIVE DISPLAY FIX - Following Project Plan
# Day 1 Morning: System Recovery & Stabilization
# Senior Project Engineer Implementation

set -e

echo "=========================================="
echo "COMPREHENSIVE DISPLAY FIX"
echo "Following: COMPREHENSIVE_2_DAY_PLAN.md"
echo "Phase: Day 1 Morning - System Recovery"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function: Proper verification
verify_display() {
    local system=$1
    local ssh_cmd=$2
    
    echo "=== PROPER VERIFICATION: $system ==="
    
    # 1. Check processes
    echo "1. Process Check:"
    PROCESSES=$($ssh_cmd "ps aux | grep -E 'chromium|cog' | grep -v grep | wc -l" 2>/dev/null || echo "0")
    echo "   Processes: $PROCESSES"
    
    # 2. Check window (for X11 systems)
    if echo "$system" | grep -q "moOde"; then
        echo "2. Window Check:"
        WINDOW_INFO=$($ssh_cmd "export DISPLAY=:0 && xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1" || echo "")
        if [ -n "$WINDOW_INFO" ]; then
            echo "   Window found: $WINDOW_INFO"
            # Extract size
            SIZE=$(echo "$WINDOW_INFO" | grep -oP '\d+x\d+' | head -1)
            echo "   Window size: $SIZE"
        else
            echo "   ${RED}❌ No window found${NC}"
        fi
        
        # 3. Check display resolution
        echo "3. Display Resolution:"
        RES=$($ssh_cmd "export DISPLAY=:0 && xrandr --query 2>/dev/null | grep connected | grep -oP '\d+x\d+' | head -1" || echo "")
        echo "   Resolution: $RES"
        
        # 4. Verify fullscreen
        if [ -n "$SIZE" ] && [ -n "$RES" ]; then
            if [ "$SIZE" == "$RES" ]; then
                echo "   ${GREEN}✅ Window matches display resolution${NC}"
                return 0
            else
                echo "   ${RED}❌ Window size ($SIZE) != Display ($RES)${NC}"
                return 1
            fi
        fi
    else
        # HiFiBerryOS - Wayland
        echo "2. Wayland Check:"
        WAYLAND=$($ssh_cmd "ps aux | grep weston | grep -v grep" 2>/dev/null || echo "")
        if [ -n "$WAYLAND" ]; then
            echo "   ${GREEN}✅ Weston running${NC}"
        else
            echo "   ${RED}❌ Weston not running${NC}"
        fi
    fi
    
    return 1
}

# Function: Fix System 2 (moOde Pi 5)
fix_system2() {
    echo "=========================================="
    echo "SYSTEM 2: moOde Pi 5 (GhettoPi4)"
    echo "=========================================="
    
    ssh pi2 << 'EOF'
set -e
export DISPLAY=:0

echo "1. Current State Analysis:"
echo "   Chromium processes:"
ps aux | grep chromium | grep -v grep | wc -l
echo "   Display resolution:"
xrandr --query | grep "HDMI-2 connected" | grep -oP '\d+x\d+' | head -1
echo "   Current windows:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -2

echo ""
echo "2. Stopping all Chromium instances..."
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 3

echo ""
echo "3. Verifying X server is ready..."
xrandr --query >/dev/null 2>&1 || (echo "ERROR: X server not ready!" && exit 1)

echo ""
echo "4. Getting correct resolution..."
TARGET_RES=$(xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "   Target: $TARGET_RES"

echo ""
echo "5. Starting Chromium in TRUE kiosk mode..."
# Use unclutter to hide cursor, and proper kiosk mode
chromium-browser \
    --kiosk \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --disable-features=TranslateUI \
    --window-size=$TARGET_RES \
    --window-position=0,0 \
    --app=http://localhost \
    >/dev/null 2>&1 &

CHROMIUM_PID=$!
echo "   Started with PID: $CHROMIUM_PID"

echo ""
echo "6. Waiting for Chromium to initialize..."
sleep 8

echo ""
echo "7. Finding Chromium window and forcing fullscreen..."
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    echo "   Window ID: $WINDOW"
    
    # Get current geometry
    CURRENT_GEOM=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}')
    echo "   Current geometry: $CURRENT_GEOM"
    
    # Activate and go fullscreen
    xdotool windowactivate $WINDOW
    sleep 1
    xdotool key F11
    sleep 2
    
    # Verify
    NEW_GEOM=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}')
    echo "   New geometry: $NEW_GEOM"
    
    # Also try to resize directly
    if [ "$TARGET_RES" == "1280x400" ]; then
        xdotool windowsize $WINDOW 1280 400
        xdotool windowmove $WINDOW 0 0
        sleep 1
    fi
else
    echo "   ${RED}ERROR: Could not find Chromium window${NC}"
    exit 1
fi

echo ""
echo "8. Final verification:"
FINAL_WINDOW=$(xwininfo -root -tree 2>/dev/null | grep -i chromium | grep "$TARGET_RES" || echo "")
if [ -n "$FINAL_WINDOW" ]; then
    echo "   ${GREEN}✅ Window found with correct resolution${NC}"
else
    echo "   Window status:"
    xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1
fi

echo ""
echo "9. Verifying web server responds:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost || echo "Web server check failed"
EOF

    echo ""
    if verify_display "System 2 (moOde Pi 5)" "ssh pi2"; then
        echo -e "${GREEN}✅ System 2 FIXED${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ System 2 needs more work${NC}"
        return 1
    fi
}

# Function: Fix System 3 (moOde Pi 4)
fix_system3() {
    echo "=========================================="
    echo "SYSTEM 3: moOde Pi 4 (MoodePi4)"
    echo "=========================================="
    
    ssh pi3 << 'EOF'
set -e

echo "1. Ensuring localdisplay service is running..."
sudo systemctl start localdisplay 2>/dev/null || true
sleep 5

# Wait for X server
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    export DISPLAY=:0
    if xrandr --query >/dev/null 2>&1; then
        echo "   ${GREEN}✅ X server ready after ${WAITED}s${NC}"
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "   ${RED}ERROR: X server not ready after ${MAX_WAIT}s${NC}"
    exit 1
fi

export DISPLAY=:0

echo ""
echo "2. Current State Analysis:"
echo "   Localdisplay service:"
systemctl is-active localdisplay
echo "   Display resolution:"
xrandr --query | grep "HDMI-2 connected" | grep -oP '\d+x\d+' | head -1
echo "   Chromium processes:"
ps aux | grep chromium | grep -v grep | wc -l

echo ""
echo "3. Stopping all Chromium instances..."
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 3

echo ""
echo "4. Getting correct resolution..."
TARGET_RES=$(xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "   Target: $TARGET_RES"

echo ""
echo "5. Starting Chromium in TRUE kiosk mode..."
chromium-browser \
    --kiosk \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --disable-features=TranslateUI \
    --window-size=$TARGET_RES \
    --window-position=0,0 \
    --app=http://localhost \
    >/dev/null 2>&1 &

CHROMIUM_PID=$!
echo "   Started with PID: $CHROMIUM_PID"

echo ""
echo "6. Waiting for Chromium to initialize..."
sleep 8

echo ""
echo "7. Finding Chromium window and forcing fullscreen..."
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    echo "   Window ID: $WINDOW"
    
    xdotool windowactivate $WINDOW
    sleep 1
    xdotool key F11
    sleep 2
    
    # Resize directly
    if [ "$TARGET_RES" == "400x1280" ]; then
        xdotool windowsize $WINDOW 400 1280
        xdotool windowmove $WINDOW 0 0
        sleep 1
    fi
else
    echo "   ${RED}ERROR: Could not find Chromium window${NC}"
    exit 1
fi

echo ""
echo "8. Final verification:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1

echo ""
echo "9. Verifying web server responds:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost || echo "Web server check failed"
EOF

    echo ""
    if verify_display "System 3 (moOde Pi 4)" "ssh pi3"; then
        echo -e "${GREEN}✅ System 3 FIXED${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ System 3 needs more work${NC}"
        return 1
    fi
}

# Function: Fix System 1 (HiFiBerryOS)
fix_system1() {
    echo "=========================================="
    echo "SYSTEM 1: HiFiBerryOS Pi 4"
    echo "=========================================="
    
    ssh pi1 << 'EOF'
echo "1. Checking touchscreen hardware..."
echo "   Input devices:"
ls -la /dev/input/event* 2>/dev/null | head -5

echo ""
echo "2. Checking touchscreen in device tree:"
cat /proc/bus/input/devices | grep -A 10 -i "touch\|FT6236\|Goodix" | head -20

echo ""
echo "3. Checking Weston configuration..."
cat /etc/xdg/weston/weston.ini 2>/dev/null | grep -A 5 -i "input\|touch" || echo "No touch config found"

echo ""
echo "4. Checking if touch device is recognized by Weston..."
export XDG_RUNTIME_DIR=/var/run/weston
weston-info 2>/dev/null | grep -i "touch\|pointer" || echo "Weston info not available"

echo ""
echo "5. Checking libinput devices:"
libinput list-devices 2>/dev/null | grep -A 5 -i "touch" || echo "libinput not available"

echo ""
echo "6. Checking cog browser status:"
ps aux | grep cog | grep -v grep
EOF

    echo ""
    echo "Touchscreen diagnosis complete. Need to check configuration files."
}

# Main execution
echo "Starting comprehensive display fix..."
echo ""

# System 2
if ping -c 1 -W 1000 192.168.178.134 >/dev/null 2>&1; then
    fix_system2
    echo ""
else
    echo -e "${RED}❌ System 2 offline${NC}"
    echo ""
fi

# System 3
PI3_IP=$(ping -c 1 -W 1000 moodepi4.local 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
if [ -n "$PI3_IP" ]; then
    fix_system3
    echo ""
else
    echo -e "${RED}❌ System 3 offline${NC}"
    echo ""
fi

# System 1
if ping -c 1 -W 1000 192.168.178.199 >/dev/null 2>&1; then
    fix_system1
    echo ""
else
    echo -e "${RED}❌ System 1 offline${NC}"
    echo ""
fi

echo "=========================================="
echo "COMPREHENSIVE FIX COMPLETE"
echo "=========================================="
echo "Date: $(date)"
echo ""
echo "Please check displays manually to verify!"
echo ""

