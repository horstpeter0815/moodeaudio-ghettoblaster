#!/bin/bash
# FIND PI 5 IP ADDRESS
# Scans network to find Pi 5

echo "=========================================="
echo "FINDING PI 5 IP ADDRESS"
echo "=========================================="
echo ""

# Get local network
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
NETWORK=$(echo $LOCAL_IP | cut -d'.' -f1-3)

echo "Local IP: $LOCAL_IP"
echo "Network: $NETWORK.0/24"
echo ""
echo "Scanning network for Pi 5..."
echo ""

# Try known IPs first
KNOWN_IPS=("192.168.178.134" "192.168.178.135" "192.168.178.136" "192.168.1.134" "192.168.1.135")

for IP in "${KNOWN_IPS[@]}"; do
    echo -n "Checking $IP... "
    if ping -c 1 -W 1000 "$IP" >/dev/null 2>&1; then
        if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no andre@"$IP" "hostname" 2>/dev/null | grep -qi "pi\|moode\|ghetto"; then
            echo "✅ FOUND! Pi 5 is at $IP"
            echo ""
            echo "Testing connection..."
            ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no andre@"$IP" << 'TEST'
echo "✅ Connected!"
hostname
uptime -p
TEST
            echo ""
            echo "=========================================="
            echo "PI 5 FOUND AT: $IP"
            echo "=========================================="
            exit 0
        else
            echo "❌ (not Pi 5)"
        fi
    else
        echo "❌ (not reachable)"
    fi
done

echo ""
echo "Scanning full network range..."
echo "(This may take a while)"
echo ""

# Scan network
for i in {1..254}; do
    IP="$NETWORK.$i"
    if [ "$IP" != "$LOCAL_IP" ]; then
        if ping -c 1 -W 500 "$IP" >/dev/null 2>&1; then
            echo -n "Found device at $IP... "
            if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no andre@"$IP" "hostname" 2>/dev/null | grep -qi "pi\|moode\|ghetto"; then
                echo "✅ FOUND PI 5!"
                echo ""
                echo "=========================================="
                echo "PI 5 FOUND AT: $IP"
                echo "=========================================="
                exit 0
            else
                echo "❌ (not Pi 5)"
            fi
        fi
    fi
done

echo ""
echo "❌ Pi 5 not found in network scan"
echo ""
echo "Please check:"
echo "  1. Is Pi 5 powered on?"
echo "  2. Is Pi 5 connected to network?"
echo "  3. What IP does Pi 5 show on its display?"
echo ""

