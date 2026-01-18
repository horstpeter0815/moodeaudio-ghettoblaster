#!/bin/bash
# Deploy and run radio/playback fix on Pi
# Usage: ./DEPLOY_AND_FIX_RADIO.sh

set -e

PI_HOST="${PI_HOST:-192.168.10.2}"
PI_USER="${PI_USER:-andre}"
PI_PASS="${PI_PASS:-0815}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIX_SCRIPT="$PROJECT_ROOT/scripts/audio/FIX_RADIO_AND_PLAYBACK.sh"
REMOTE_SCRIPT="/tmp/fix-radio-playback.sh"

echo "=== Deploying Radio/Playback Fix ==="
echo "Pi: $PI_USER@$PI_HOST"
echo ""

# Check if Pi is reachable
if ! ping -c 1 -W 1 "$PI_HOST" >/dev/null 2>&1; then
    echo "❌ Cannot reach $PI_HOST"
    echo "   Is the Pi powered on and connected?"
    exit 1
fi

# Check for sshpass
if ! command -v sshpass >/dev/null 2>&1; then
    echo "Installing sshpass..."
    if command -v brew >/dev/null 2>&1; then
        brew install hudochenkov/sshpass/sshpass || {
            echo "❌ Failed to install sshpass"
            echo "   Install manually: brew install hudochenkov/sshpass/sshpass"
            exit 1
        }
    else
        echo "❌ sshpass not found and Homebrew not available"
        exit 1
    fi
fi

# Copy fix script to Pi
echo "Copying fix script to Pi..."
sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=accept-new \
    "$FIX_SCRIPT" "$PI_USER@$PI_HOST:$REMOTE_SCRIPT" || {
    echo "❌ Failed to copy script"
    exit 1
}

# Make executable and run
echo "Running fix script on Pi..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" \
    "chmod +x $REMOTE_SCRIPT && sudo bash $REMOTE_SCRIPT" || {
    echo "❌ Failed to run fix script"
    exit 1
}

echo ""
echo "✅ Fix deployed and executed!"
echo ""
echo "Next steps:"
echo "  1. Clear browser cache (Ctrl+Shift+Delete)"
echo "  2. Hard refresh moOde web interface (Ctrl+F5)"
echo "  3. Check Radio section"
echo "  4. Try playing a station"
echo ""
