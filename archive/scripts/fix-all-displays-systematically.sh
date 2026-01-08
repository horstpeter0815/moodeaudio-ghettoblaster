#!/bin/bash
# SYSTEMATIC DISPLAY FIX - Following Project Plan
# Day 1 Morning: System Recovery & Stabilization
# Senior Project Engineer Implementation

set -e

echo "=========================================="
echo "SYSTEMATIC DISPLAY FIX - ALL SYSTEMS"
echo "Following: COMPREHENSIVE_2_DAY_PLAN.md"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function: Proper verification with window size check
verify_display_working() {
    local system=$1
    local ssh_cmd=$2
    local expected_res=$3
    
    echo "=== VERIFICATION: $system ==="
    
    if echo "$system" | grep -q "moOde"; then
        # X11 system verification
        WINDOW_INFO=$($ssh_cmd "export DISPLAY=:0 && xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1" || echo "")
        if [ -z "$WINDOW_INFO" ]; then
            echo -e "   ${RED}❌ No Chromium window found${NC}"
            return 1
        fi
        
        # Extract window size
        WINDOW_SIZE=$(echo "$WINDOW_INFO" | grep -oP '\d+x\d+' | head -1)
        echo "   Window size: $WINDOW_SIZE"
        
        # Get display resolution
        DISPLAY_RES=$($ssh_cmd "export DISPLAY=:0 && xrandr --query 2>/dev/null | grep connected | grep -oP '\d+x\d+' | head -1" || echo "")
        echo "   Display resolution: $DISPLAY_RES"
        
        # Check if they match
        if [ -n "$WINDOW_SIZE" ] && [ -n "$DISPLAY_RES" ]; then
            if [ "$WINDOW_SIZE" == "$DISPLAY_RES" ] || echo "$WINDOW_INFO" | grep -q "fullscreen\|1280x400\|400x1280"; then
                echo -e "   ${GREEN}✅ Display working correctly${NC}"
                return 0
            else
                echo -e "   ${YELLOW}⚠️  Size mismatch: Window=$WINDOW_SIZE, Display=$DISPLAY_RES${NC}"
                return 1
            fi
        fi
    else
        # HiFiBerryOS - check processes
        PROCESSES=$($ssh_cmd "ps aux | grep -E 'cog|weston' | grep -v grep | wc -l" 2>/dev/null || echo "0")
        if [ "$PROCESSES" -gt "0" ]; then
            echo -e "   ${GREEN}✅ Display processes running: $PROCESSES${NC}"
            return 0
        else
            echo -e "   ${RED}❌ No display processes${NC}"
            return 1
        fi
    fi
    
    return 1
}

# System 2: Restart and verify
echo "=========================================="
echo "SYSTEM 2: moOde Pi 5 - RESTART & VERIFY"
echo "=========================================="

ssh pi2 << 'EOF'
echo "1. Stopping localdisplay service..."
sudo systemctl stop localdisplay 2>/dev/null || true
sleep 2

echo "2. Killing all X and Chromium processes..."
pkill -9 chromium 2>/dev/null || true
pkill -9 Xorg 2>/dev/null || true
pkill -9 xinit 2>/dev/null || true
sleep 2

echo "3. Starting localdisplay service..."
sudo systemctl start localdisplay

echo "4. Waiting for X server to start..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    export DISPLAY=:0
    if xrandr --query >/dev/null 2>&1; then
        echo "   ✅ X server ready after ${WAITED}s"
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "   ❌ X server not ready after ${MAX_WAIT}s"
    exit 1
fi

echo ""
echo "5. Waiting for Chromium to start..."
sleep 8

echo ""
echo "6. Checking Chromium..."
ps aux | grep chromium | grep -v grep | head -2
EOF

echo ""
if verify_display_working "System 2 (moOde Pi 5)" "ssh pi2" "1280x400"; then
    echo -e "${GREEN}✅ System 2 FIXED AND VERIFIED${NC}"
    TODO_STATUS_2="completed"
else
    echo -e "${YELLOW}⚠️ System 2 needs more verification${NC}"
    TODO_STATUS_2="in_progress"
fi

echo ""
echo "=========================================="
echo "SYSTEM 3: moOde Pi 4 - RESTART & VERIFY"
echo "=========================================="

ssh pi3 << 'EOF'
echo "1. Stopping localdisplay service..."
sudo systemctl stop localdisplay 2>/dev/null || true
sleep 2

echo "2. Killing all X and Chromium processes..."
pkill -9 chromium 2>/dev/null || true
pkill -9 Xorg 2>/dev/null || true
pkill -9 xinit 2>/dev/null || true
sleep 2

echo "3. Starting localdisplay service..."
sudo systemctl start localdisplay

echo "4. Waiting for X server to start..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    export DISPLAY=:0
    if xrandr --query >/dev/null 2>&1; then
        echo "   ✅ X server ready after ${WAITED}s"
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "   ❌ X server not ready after ${MAX_WAIT}s"
    exit 1
fi

echo ""
echo "5. Waiting for Chromium to start..."
sleep 8

echo ""
echo "6. Checking Chromium..."
ps aux | grep chromium | grep -v grep | head -2
EOF

echo ""
if verify_display_working "System 3 (moOde Pi 4)" "ssh pi3" "400x1280"; then
    echo -e "${GREEN}✅ System 3 FIXED AND VERIFIED${NC}"
    TODO_STATUS_3="completed"
else
    echo -e "${YELLOW}⚠️ System 3 needs more verification${NC}"
    TODO_STATUS_3="in_progress"
fi

echo ""
echo "=========================================="
echo "SYSTEM 1: HiFiBerryOS - TOUCHSCREEN FIX"
echo "=========================================="

ssh pi1 << 'EOF'
echo "1. Checking touchscreen hardware..."
echo "   Input devices:"
ls -la /dev/input/event* 2>/dev/null | head -5

echo ""
echo "2. Checking touchscreen in device tree:"
cat /proc/bus/input/devices | grep -A 10 -i "touch\|FT6236\|Goodix" | head -25

echo ""
echo "3. Checking Weston configuration..."
if [ -f /etc/xdg/weston/weston.ini ]; then
    echo "   Weston.ini exists"
    cat /etc/xdg/weston/weston.ini | grep -A 10 -i "input\|touch\|libinput" || echo "   No touch config in weston.ini"
else
    echo "   No weston.ini found"
fi

echo ""
echo "4. Checking libinput devices..."
libinput list-devices 2>/dev/null | grep -A 5 -i "touch" || echo "   libinput not available or no touch found"

echo ""
echo "5. Checking if touch device exists..."
for dev in /dev/input/event*; do
    if [ -e "$dev" ]; then
        echo "   Found: $dev"
        udevadm info "$dev" 2>/dev/null | grep -i "name\|touch" || true
    fi
done
EOF

echo ""
echo "=========================================="
echo "FINAL STATUS"
echo "=========================================="
echo ""
echo "System 2 (moOde Pi 5): $TODO_STATUS_2"
echo "System 3 (moOde Pi 4): $TODO_STATUS_3"
echo "System 1 (HiFiBerryOS): Touchscreen diagnosis complete"
echo ""
echo "Please check displays manually to verify!"
echo ""

