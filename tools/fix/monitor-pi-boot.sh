#!/bin/bash
# Proactive Pi boot monitoring - checks Pi status automatically

set -e

PI_IP="${1}"
PI_USER="andre"
PI_PASS="0815"

if [ -z "$PI_IP" ]; then
    echo "Usage: $0 <PI_IP_ADDRESS>"
    echo ""
    echo "This script monitors the Pi boot process and checks status."
    exit 1
fi

echo "=== PROACTIVE PI BOOT MONITORING ==="
echo ""
echo "Monitoring Pi at: $PI_IP"
echo ""

# Wait for Pi to become reachable
echo "Waiting for Pi to become reachable..."
for i in {1..60}; do
    if ping -c 1 -W 1 "$PI_IP" >/dev/null 2>&1; then
        echo "✅ Pi is reachable!"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Wait for SSH to be available
echo "Waiting for SSH..."
for i in {1..60}; do
    if nc -z -w 1 "$PI_IP" 22 2>/dev/null; then
        echo "✅ SSH is available!"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Check system status
echo "=== CHECKING SYSTEM STATUS ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$PI_USER@$PI_IP" << 'EOF'
echo "=== BOOT STATUS ==="
echo ""
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
echo ""

echo "=== FAILED SERVICES ==="
FAILED=$(systemctl --failed --no-pager 2>&1)
if echo "$FAILED" | grep -q "0 loaded units listed"; then
    echo "✅ No failed services!"
else
    echo "$FAILED"
fi
echo ""

echo "=== SSH STATUS ==="
systemctl status ssh sshd 2>&1 | grep -E "Active:|Loaded:|since" | head -5
echo ""

echo "=== NETWORK STATUS ==="
ip addr show | grep -E "inet " | head -3
echo ""

echo "=== KEY SERVICES STATUS ==="
for svc in NetworkManager ssh sshd; do
    STATUS=$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")
    echo "$svc: $STATUS"
done
echo ""

echo "=== RECENT BOOT MESSAGES ==="
journalctl -b --no-pager 2>&1 | grep -E "ssh|SSH|Started|Failed" | tail -10
EOF

echo ""
echo "=== MONITORING COMPLETE ==="
