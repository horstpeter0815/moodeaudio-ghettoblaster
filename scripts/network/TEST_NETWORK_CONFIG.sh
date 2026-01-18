#!/bin/bash
# Comprehensive Network Configuration Test
# Tests all IP addresses, connections, and network status

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧪 NETWORK CONFIGURATION TEST                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
PI_USER="andre"
PI_PASSWORD="0815"
KNOWN_IPS=("192.168.10.2" "192.168.1.159" "192.168.1.100")
HOSTNAMES=("ghettoblaster.local" "moodepi5.local")
FORBIDDEN_IP="192.168.1.101"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
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

# Test 1: Verify forbidden IP is not used
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Verify .101 IP is NOT used"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ping -c 1 -W 1 "$FORBIDDEN_IP" >/dev/null 2>&1; then
    test_result 1 "Forbidden IP $FORBIDDEN_IP is reachable (this is a ROUTER, not the Pi!)"
else
    test_result 0 "Forbidden IP $FORBIDDEN_IP is not reachable (correct - it's a router)"
fi
echo ""

# Test 2: Test hostname resolution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Hostname Resolution (mDNS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REACHABLE_HOSTNAME=""
for hostname in "${HOSTNAMES[@]}"; do
    if ping -c 1 -W 2 "$hostname" >/dev/null 2>&1; then
        test_result 0 "Hostname $hostname is reachable"
        REACHABLE_HOSTNAME="$hostname"
        break
    else
        test_result 1 "Hostname $hostname is not reachable"
    fi
done
echo ""

# Test 3: Test IP addresses
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: IP Address Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REACHABLE_IP=""
for ip in "${KNOWN_IPS[@]}"; do
    if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
        test_result 0 "IP $ip is reachable"
        REACHABLE_IP="$ip"
    else
        test_result 1 "IP $ip is not reachable"
    fi
done
echo ""

# Test 4: SSH Connectivity
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: SSH Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SSH_TARGET=""
if [ -n "$REACHABLE_HOSTNAME" ]; then
    SSH_TARGET="$REACHABLE_HOSTNAME"
elif [ -n "$REACHABLE_IP" ]; then
    SSH_TARGET="$REACHABLE_IP"
fi

if [ -n "$SSH_TARGET" ]; then
    # Check if sshpass is available
    if command -v sshpass >/dev/null 2>&1; then
        if sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 "$PI_USER@$SSH_TARGET" 'echo "SSH connection successful"' >/dev/null 2>&1; then
            test_result 0 "SSH to $PI_USER@$SSH_TARGET successful"
        else
            test_result 1 "SSH to $PI_USER@$SSH_TARGET failed"
        fi
    else
        echo -e "${YELLOW}⚠️  SKIP${NC}: sshpass not installed, cannot test SSH automatically"
        echo "   Manual test: ssh $PI_USER@$SSH_TARGET"
    fi
else
    test_result 1 "No reachable target for SSH test"
fi
echo ""

# Test 5: Network Status (if SSH available)
if [ -n "$SSH_TARGET" ] && command -v sshpass >/dev/null 2>&1; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 5: Network Status on Pi"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    NETWORK_INFO=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$PI_USER@$SSH_TARGET" 'hostname -I && echo "---" && nmcli device status 2>/dev/null || echo "NetworkManager not available"' 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        test_result 0 "Retrieved network status from Pi"
        echo ""
        echo "Network Information:"
        echo "$NETWORK_INFO" | while IFS= read -r line; do
            echo "  $line"
        done
    else
        test_result 1 "Failed to retrieve network status"
    fi
    echo ""
    
    # Test 6: WiFi Connection Status
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 6: WiFi Connection Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    WIFI_STATUS=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$PI_USER@$SSH_TARGET" 'nmcli connection show --active | grep -i wifi || echo "No WiFi connection"' 2>/dev/null)
    
    if echo "$WIFI_STATUS" | grep -qi "wifi\|nam-yang"; then
        test_result 0 "WiFi connection active"
        echo "  $WIFI_STATUS"
    else
        test_result 1 "WiFi connection not active or not found"
    fi
    echo ""
    
    # Test 7: Current IP Addresses
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 7: Current IP Addresses"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    IP_ADDRESSES=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$PI_USER@$SSH_TARGET" 'ip -4 addr show | grep "inet " | awk "{print \$2}" | cut -d/ -f1' 2>/dev/null)
    
    if [ -n "$IP_ADDRESSES" ]; then
        test_result 0 "Retrieved IP addresses"
        echo "  Current IPs:"
        echo "$IP_ADDRESSES" | while IFS= read -r ip; do
            if [ "$ip" = "$FORBIDDEN_IP" ]; then
                echo -e "    ${RED}⚠️  $ip (FORBIDDEN - This is a router!)${NC}"
            else
                echo "    ✅ $ip"
            fi
        done
    else
        test_result 1 "Failed to retrieve IP addresses"
    fi
    echo ""
fi

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
    echo -e "${RED}❌ Some tests failed. Please review above.${NC}"
    exit 1
fi
