#!/bin/bash
# Monitor Pi Boot
# Monitor Raspberry Pi boot process in real-time
# Part of: WISSENSBASIS/DEVELOPMENT_WORKFLOW.md tooling

PI_IP="${1:-192.168.2.3}"
USER="${2:-andre}"

echo "========================================"
echo "Monitoring Pi Boot Process"
echo "Target: $USER@$PI_IP"
echo "========================================"
echo ""
echo "Waiting for Pi to become reachable..."
echo "(This may take 30-60 seconds after power on)"
echo ""

# Wait for Pi to be reachable
TIMEOUT=120
ELAPSED=0
while ! ping -c 1 -W 1 "$PI_IP" >/dev/null 2>&1; do
    echo -n "."
    sleep 1
    ((ELAPSED++))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ""
        echo "Timeout: Pi not reachable after $TIMEOUT seconds"
        exit 1
    fi
done

echo ""
echo "✓ Pi is reachable!"
echo ""

# Wait for SSH
echo "Waiting for SSH..."
ELAPSED=0
while ! ssh -o ConnectTimeout=1 -o BatchMode=yes "$USER@$PI_IP" "true" 2>/dev/null; do
    echo -n "."
    sleep 1
    ((ELAPSED++))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ""
        echo "Timeout: SSH not available after $TIMEOUT seconds"
        exit 1
    fi
done

echo ""
echo "✓ SSH is ready!"
echo ""

echo "=== Boot Messages (last 50 lines) ==="
ssh "$USER@$PI_IP" "journalctl -b -n 50 --no-pager"
echo ""

echo "=== Current System Status ==="
ssh "$USER@$PI_IP" "systemctl is-system-running || true"
echo ""

echo "=== Failed Services (if any) ==="
ssh "$USER@$PI_IP" "systemctl list-units --failed --no-pager || true"
echo ""

echo "=== X Server Status ==="
ssh "$USER@$PI_IP" "systemctl status localdisplay 2>&1 | grep -E 'Active|Main PID' || echo 'Not running'"
echo ""

echo "========================================"
echo "Boot monitoring complete"
echo "========================================"
echo ""
echo "For more details:"
echo "  ssh $USER@$PI_IP 'journalctl -b'"
echo ""
echo "To check system status:"
echo "  toolbox/system/check-system-status.sh"
