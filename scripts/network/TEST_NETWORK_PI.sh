#!/bin/bash
# Network Test Script - Run directly on Pi
# Copy this to Pi and run: bash TEST_NETWORK_PI.sh

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧪 NETWORK CONFIGURATION TEST (Pi Local)                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

test_result() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: Check all IP addresses
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Current IP Addresses"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
IP_ADDRESSES=$(hostname -I)
if [ -n "$IP_ADDRESSES" ]; then
    test_result 0 "IP addresses found"
    echo -e "${BLUE}  Current IPs:${NC}"
    for ip in $IP_ADDRESSES; do
        if [ "$ip" = "192.168.1.101" ]; then
            echo -e "    ${RED}⚠️  $ip (FORBIDDEN - This is a router!)${NC}"
        else
            echo "    ✅ $ip"
        fi
    done
else
    test_result 1 "No IP addresses found"
fi
echo ""

# Test 2: Detailed IP information
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Network Interface Details"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ip addr show >/dev/null 2>&1; then
    test_result 0 "Network interfaces accessible"
    echo -e "${BLUE}  Interface Details:${NC}"
    ip -4 addr show | grep -E "^[0-9]|inet " | while IFS= read -r line; do
        if [[ $line =~ ^[0-9] ]]; then
            echo "  $line"
        else
            echo "    $line"
        fi
    done
else
    test_result 1 "Cannot access network interfaces"
fi
echo ""

# Test 3: NetworkManager Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: NetworkManager Device Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v nmcli >/dev/null 2>&1; then
    test_result 0 "NetworkManager (nmcli) available"
    echo -e "${BLUE}  Device Status:${NC}"
    nmcli device status
else
    test_result 1 "NetworkManager (nmcli) not available"
fi
echo ""

# Test 4: Active Connections
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Active Network Connections"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v nmcli >/dev/null 2>&1; then
    ACTIVE_CONNECTIONS=$(nmcli connection show --active 2>/dev/null)
    if [ -n "$ACTIVE_CONNECTIONS" ]; then
        test_result 0 "Active connections found"
        echo -e "${BLUE}  Active Connections:${NC}"
        echo "$ACTIVE_CONNECTIONS"
    else
        test_result 1 "No active connections"
    fi
else
    test_result 1 "NetworkManager not available"
fi
echo ""

# Test 5: WiFi Connection Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5: WiFi Connection Details"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v nmcli >/dev/null 2>&1; then
    WIFI_CONN=$(nmcli connection show --active | grep -i wifi || echo "")
    if [ -n "$WIFI_CONN" ]; then
        CONN_NAME=$(echo "$WIFI_CONN" | awk '{print $1}')
        test_result 0 "WiFi connection active: $CONN_NAME"
        echo -e "${BLUE}  WiFi Connection Details:${NC}"
        nmcli connection show "$CONN_NAME" 2>/dev/null | grep -E "802-11-wireless.ssid|ipv4.method|ipv4.addresses|connection.autoconnect" | while IFS= read -r line; do
            echo "    $line"
        done
    else
        test_result 1 "No WiFi connection active"
    fi
else
    test_result 1 "NetworkManager not available"
fi
echo ""

# Test 6: Available WiFi Networks
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 6: Available WiFi Networks (Scan)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v nmcli >/dev/null 2>&1; then
    echo "Scanning for WiFi networks (this may take a moment)..."
    if sudo nmcli device wifi rescan >/dev/null 2>&1; then
        sleep 3
        WIFI_LIST=$(nmcli device wifi list 2>/dev/null | head -10)
        if [ -n "$WIFI_LIST" ]; then
            test_result 0 "WiFi scan successful"
            echo -e "${BLUE}  Available Networks (first 10):${NC}"
            echo "$WIFI_LIST"
        else
            test_result 1 "WiFi scan returned no results"
        fi
    else
        test_result 1 "WiFi scan failed"
    fi
else
    test_result 1 "NetworkManager not available"
fi
echo ""

# Test 7: Hostname Resolution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 7: Hostname and DNS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
HOSTNAME=$(hostname)
if [ -n "$HOSTNAME" ]; then
    test_result 0 "Hostname: $HOSTNAME"
    echo -e "${BLUE}  Full Hostname:${NC} $(hostname -f)"
    echo -e "${BLUE}  FQDN:${NC} $(hostname -A 2>/dev/null || echo 'N/A')"
else
    test_result 1 "Hostname not set"
fi
echo ""

# Test 8: Internet Connectivity
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 8: Internet Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    test_result 0 "Internet connectivity (8.8.8.8) working"
else
    test_result 1 "Internet connectivity (8.8.8.8) not available"
fi

if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
    test_result 0 "DNS resolution (google.com) working"
else
    test_result 1 "DNS resolution (google.com) not working"
fi
echo ""

# Test 9: Routing Table
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 9: Routing Table"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ip route show >/dev/null 2>&1; then
    test_result 0 "Routing table accessible"
    echo -e "${BLUE}  Default Route:${NC}"
    ip route show default 2>/dev/null || echo "    No default route"
    echo -e "${BLUE}  All Routes:${NC}"
    ip route show | head -10
else
    test_result 1 "Cannot access routing table"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Tests: $TESTS_TOTAL"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Review above for details.${NC}"
    exit 1
fi
