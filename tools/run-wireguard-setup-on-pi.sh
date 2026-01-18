#!/bin/bash
# Copy and run WireGuard setup script on Pi
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PI_IP="${1:-192.168.2.3}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

echo "=== COPYING WIREGUARD SETUP TO PI ==="
echo ""

# Check for sshpass
if ! command -v sshpass >/dev/null 2>&1; then
    echo "⚠️  sshpass not found. Installing..."
    if command -v brew >/dev/null 2>&1; then
        brew install hudochenkov/sshpass/sshpass || {
            echo "❌ Failed to install sshpass"
            exit 1
        }
    else
        echo "❌ sshpass not found and Homebrew not available"
        exit 1
    fi
fi

# Check if Pi is reachable
if ! ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
    echo "❌ Pi not reachable at $PI_IP"
    echo "   Make sure Pi is booted and on network"
    exit 1
fi

echo "✅ Pi is reachable at $PI_IP"
echo ""

# Copy script to Pi
echo "Copying setup script to Pi..."
sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=accept-new "$SCRIPT_DIR/setup-wireguard-pi-only.sh" "$PI_USER@$PI_IP:/tmp/setup-wireguard.sh" || {
    echo "❌ Failed to copy script"
    echo "   Make sure SSH is working: ssh $PI_USER@$PI_IP"
    exit 1
}

echo "✅ Script copied"
echo ""

# Run script on Pi
echo "Running WireGuard setup on Pi..."
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_IP" "chmod +x /tmp/setup-wireguard.sh && /tmp/setup-wireguard.sh"

echo ""
echo "✅ WireGuard setup complete on Pi!"
echo ""
