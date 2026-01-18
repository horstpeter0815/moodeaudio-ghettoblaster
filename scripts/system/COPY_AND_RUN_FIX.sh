#!/bin/bash
# Copy fix script to Pi and provide instructions
# Run from HOME: bash ~/moodeaudio-cursor/scripts/system/COPY_AND_RUN_FIX.sh

PI_IP="${1:-192.168.1.159}"
PI_USER="${2:-andre}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📋 Copy Fix Script to Pi                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_PATH="$HOME/moodeaudio-cursor/scripts/system/FIX_BLACK_DISPLAY_PI.sh"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Script not found: $SCRIPT_PATH"
    exit 1
fi

echo "Script location: $SCRIPT_PATH"
echo "Target Pi: $PI_USER@$PI_IP"
echo ""

# Try to copy via SCP (will prompt for password)
echo "Attempting to copy script to Pi..."
echo "You will be prompted for password: 0815"
echo ""

scp "$SCRIPT_PATH" "$PI_USER@$PI_IP:~/fix-display.sh" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Script copied successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Next Steps:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. SSH to Pi:"
    echo "   ssh $PI_USER@$PI_IP"
    echo ""
    echo "2. Run the fix script:"
    echo "   bash ~/fix-display.sh"
    echo ""
    echo "Or run directly via SSH:"
    echo "   ssh $PI_USER@$PI_IP 'bash -s' < $SCRIPT_PATH"
    echo ""
else
    echo ""
    echo "❌ Copy failed. Manual steps:"
    echo ""
    echo "1. Copy script content manually, or"
    echo "2. SSH to Pi and create the script:"
    echo ""
    echo "   ssh $PI_USER@$PI_IP"
    echo "   nano ~/fix-display.sh"
    echo "   # Paste script content"
    echo "   chmod +x ~/fix-display.sh"
    echo "   bash ~/fix-display.sh"
    echo ""
fi
