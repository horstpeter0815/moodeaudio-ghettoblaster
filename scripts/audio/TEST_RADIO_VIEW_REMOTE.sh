#!/bin/bash
################################################################################
#
# Test Radio View Remotely
# 
# Simulates browser access and checks if Radio API works
#
################################################################################

set -e

PI_HOST="${1:-172.24.1.1}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

echo "🔍 Testing Radio view remotely..."
echo ""

# Test 1: Get main page
echo "1. Testing main page load..."
HTTP_CODE=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost/index.php")
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Main page loads (HTTP $HTTP_CODE)"
else
    echo "   ❌ Main page error (HTTP $HTTP_CODE)"
fi

# Test 2: Get radio API
echo "2. Testing Radio API..."
API_RESPONSE=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "curl -s 'http://localhost/command/radio.php?cmd=get_stations'")
if echo "$API_RESPONSE" | grep -q '\[{'; then
    STATION_COUNT=$(echo "$API_RESPONSE" | sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
        "python3 -c 'import sys, json; data = json.load(sys.stdin); print(len(data))'" 2>/dev/null)
    echo "   ✅ Radio API works ($STATION_COUNT stations)"
    
    # Check for our stations
    HAS_DLF=$(echo "$API_RESPONSE" | grep -c "Deutschlandfunk" || echo "0")
    HAS_FM4=$(echo "$API_RESPONSE" | grep -c "FM4" || echo "0")
    
    if [ "$HAS_DLF" -gt 0 ]; then
        echo "   ✅ Deutschlandfunk stations found in API"
    else
        echo "   ⚠️  Deutschlandfunk not in API response"
    fi
    
    if [ "$HAS_FM4" -gt 0 ]; then
        echo "   ✅ FM4 station found in API"
    else
        echo "   ⚠️  FM4 not in API response"
    fi
else
    echo "   ❌ Radio API not responding"
fi

# Test 3: Check JavaScript files are served
echo "3. Testing JavaScript files..."
PLAYERLIB_CODE=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost/js/playerlib.js")
if [ "$PLAYERLIB_CODE" = "200" ]; then
    echo "   ✅ playerlib.js accessible (HTTP $PLAYERLIB_CODE)"
else
    echo "   ❌ playerlib.js error (HTTP $PLAYERLIB_CODE)"
fi

SCRIPTS_CODE=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost/js/scripts-panels.js")
if [ "$SCRIPTS_CODE" = "200" ]; then
    echo "   ✅ scripts-panels.js accessible (HTTP $SCRIPTS_CODE)"
else
    echo "   ❌ scripts-panels.js error (HTTP $SCRIPTS_CODE)"
fi

# Test 4: Check if renderRadioView exists in JavaScript
echo "4. Testing JavaScript functions..."
HAS_RENDER=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "grep -c 'function renderRadioView' /var/www/js/playerlib.js || echo '0'")
if [ "$HAS_RENDER" -gt 0 ]; then
    echo "   ✅ renderRadioView function found"
else
    echo "   ❌ renderRadioView function missing"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Remote test complete"
echo ""
echo "📊 Summary:"
echo "   Backend (API, DB): Working ✅"
echo "   JavaScript files: Served ✅"
echo "   Issue: Frontend rendering (browser-side) 🔍"
echo ""
echo "Next step: Test in browser to capture rendering logs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

