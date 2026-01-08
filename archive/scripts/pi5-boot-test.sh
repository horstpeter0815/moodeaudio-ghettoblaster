#!/bin/bash
# PI 5 BOOT SEQUENCE TEST - Project Plan Requirement
# Test: System bootet 3x ohne Fehler

set -e

echo "=========================================="
echo "PI 5 BOOT SEQUENCE TEST"
echo "Project Plan Requirement: 3x boot without errors"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_COUNT=3
SUCCESS_COUNT=0

for i in $(seq 1 $TEST_COUNT); do
    echo "=========================================="
    echo "BOOT TEST $i of $TEST_COUNT"
    echo "=========================================="
    
    echo "Step 1: Rebooting Pi 5..."
    ssh pi2 "sudo reboot" || true
    
    echo "Step 2: Waiting for system to go offline..."
    sleep 10
    
    echo "Step 3: Waiting for system to come back online..."
    MAX_WAIT=120
    WAITED=0
    ONLINE=false
    
    while [ $WAITED -lt $MAX_WAIT ]; do
        if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
            ONLINE=true
            echo -e "${GREEN}✅ System online after ${WAITED}s${NC}"
            break
        fi
        sleep 2
        WAITED=$((WAITED + 2))
        echo -n "."
    done
    
    if [ "$ONLINE" = false ]; then
        echo -e "${RED}❌ System did not come online within ${MAX_WAIT}s${NC}"
        continue
    fi
    
    echo ""
    echo "Step 4: Waiting for SSH..."
    sleep 10
    
    echo "Step 5: Waiting for services to start..."
    MAX_SERVICE_WAIT=60
    SERVICE_WAITED=0
    SERVICES_READY=false
    
    while [ $SERVICE_WAITED -lt $MAX_SERVICE_WAIT ]; do
        if ssh -o ConnectTimeout=5 pi2 "systemctl is-active localdisplay mpd nginx" >/dev/null 2>&1; then
            SERVICES_READY=true
            echo -e "${GREEN}✅ Services ready after ${SERVICE_WAITED}s${NC}"
            break
        fi
        sleep 3
        SERVICE_WAITED=$((SERVICE_WAITED + 3))
        echo -n "."
    done
    
    if [ "$SERVICES_READY" = false ]; then
        echo -e "${YELLOW}⚠️ Services not all ready within ${MAX_SERVICE_WAIT}s${NC}"
    fi
    
    echo ""
    echo "Step 6: Verifying system status..."
    
    # Check services
    echo "  - Services:"
    ssh pi2 "systemctl is-active localdisplay && systemctl is-active mpd && systemctl is-active nginx" || echo "  ⚠️ Some services not active"
    
    # Check display
    echo "  - Display:"
    DISPLAY_STATUS=$(ssh pi2 "export DISPLAY=:0 && xrandr --query 2>/dev/null | grep 'HDMI-2 connected' | grep -oP '\d+x\d+' | head -1" || echo "")
    if [ -n "$DISPLAY_STATUS" ]; then
        echo -e "  ${GREEN}✅ Display: $DISPLAY_STATUS${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Display not ready${NC}"
    fi
    
    # Check Chromium
    echo "  - Chromium:"
    CHROMIUM_COUNT=$(ssh pi2 "ps aux | grep chromium | grep -v grep | wc -l" || echo "0")
    if [ "$CHROMIUM_COUNT" -gt "0" ]; then
        echo -e "  ${GREEN}✅ Chromium running ($CHROMIUM_COUNT processes)${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Chromium not running${NC}"
    fi
    
    # Check window size
    echo "  - Window size:"
    WINDOW_SIZE=$(ssh pi2 "export DISPLAY=:0 && xdotool search --class Chromium 2>/dev/null | head -1 | xargs -I {} xdotool getwindowgeometry {} 2>/dev/null | grep Geometry | awk '{print \$2}'" || echo "")
    if [ -n "$WINDOW_SIZE" ]; then
        if echo "$WINDOW_SIZE" | grep -q "1280x400"; then
            echo -e "  ${GREEN}✅ Window: $WINDOW_SIZE${NC}"
        else
            echo -e "  ${YELLOW}⚠️ Window: $WINDOW_SIZE (should be 1280x400)${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️ Could not check window size${NC}"
    fi
    
    echo ""
    echo "Step 7: Boot test $i result..."
    
    # Determine if boot was successful
    if [ "$ONLINE" = true ] && [ "$SERVICES_READY" = true ] && [ "$CHROMIUM_COUNT" -gt "0" ]; then
        echo -e "${GREEN}✅ BOOT TEST $i: SUCCESS${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "${YELLOW}⚠️ BOOT TEST $i: PARTIAL SUCCESS${NC}"
    fi
    
    echo ""
    
    # Wait before next reboot (except for last test)
    if [ $i -lt $TEST_COUNT ]; then
        echo "Waiting 30 seconds before next test..."
        sleep 30
    fi
done

echo "=========================================="
echo "BOOT TEST SUMMARY"
echo "=========================================="
echo "Total tests: $TEST_COUNT"
echo "Successful: $SUCCESS_COUNT"
echo ""

if [ $SUCCESS_COUNT -eq $TEST_COUNT ]; then
    echo -e "${GREEN}✅ ALL BOOT TESTS PASSED!${NC}"
    echo "Project plan requirement met: System bootet 3x ohne Fehler"
    exit 0
else
    echo -e "${YELLOW}⚠️ $SUCCESS_COUNT/$TEST_COUNT tests passed${NC}"
    exit 1
fi

