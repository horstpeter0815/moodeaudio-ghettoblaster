#!/bin/bash
# Deploy PeppyMeter Toggle Fix to Raspberry Pi
# Part of: DEVELOPMENT_WORKFLOW.md Phase 5: VERIFY & DOCUMENT

PI_IP="${1:-192.168.2.3}"
USER="${2:-andre}"
WORKSPACE_ROOT="/Users/andrevollmer/moodeaudio-cursor"

echo "========================================"
echo "Deploy PeppyMeter Toggle Fix"
echo "Target: $USER@$PI_IP"
echo "========================================"
echo ""

# Check if Pi is reachable
echo "1. Checking if Pi is reachable..."
if ! ping -c 1 -W 2 "$PI_IP" &>/dev/null; then
    echo "❌ ERROR: Pi is not reachable at $PI_IP"
    echo "   Please check:"
    echo "   - Is the Pi powered on?"
    echo "   - Is it connected to the network?"
    echo "   - Is the IP address correct?"
    exit 1
fi
echo "✅ Pi is reachable"
echo ""

# Copy modified files to Pi
echo "2. Copying modified files to Pi..."

echo "   → Copying playback.php..."
scp "$WORKSPACE_ROOT/moode-source/www/command/playback.php" \
    "$USER@$PI_IP:/tmp/playback.php" || exit 1

echo "   → Copying indextpl.html..."
scp "$WORKSPACE_ROOT/moode-source/www/templates/indextpl.html" \
    "$USER@$PI_IP:/tmp/indextpl.html" || exit 1

echo "✅ Files copied to /tmp/"
echo ""

# Move files to correct locations (requires sudo)
echo "3. Installing files on Pi..."
ssh "$USER@$PI_IP" "sudo cp /tmp/playback.php /var/www/command/playback.php && \
                     sudo cp /tmp/indextpl.html /var/www/templates/indextpl.html && \
                     sudo chown www-data:www-data /var/www/command/playback.php && \
                     sudo chown www-data:www-data /var/www/templates/indextpl.html && \
                     sudo chmod 644 /var/www/command/playback.php && \
                     sudo chmod 644 /var/www/templates/indextpl.html && \
                     rm /tmp/playback.php /tmp/indextpl.html" || exit 1

echo "✅ Files installed"
echo ""

# Clear browser cache and reload services
echo "4. Clearing browser cache and reloading services..."
ssh "$USER@$PI_IP" "/var/www/util/sysutil.sh clearbrcache" || echo "⚠️  Cache clear failed (might not exist)"
ssh "$USER@$PI_IP" "sudo systemctl reload nginx" || exit 1
ssh "$USER@$PI_IP" "sudo systemctl reload php8.4-fpm" || exit 1

echo "✅ Services reloaded"
echo ""

# Verify installation
echo "5. Verifying installation..."
echo "   Checking if toggle_peppymeter exists in playback.php:"
ssh "$USER@$PI_IP" "grep -q 'toggle_peppymeter' /var/www/command/playback.php && echo '✅ Backend handler found' || echo '❌ Backend handler NOT found'"

echo "   Checking if button exists in indextpl.html:"
ssh "$USER@$PI_IP" "grep -q 'toggle-peppymeter' /var/www/templates/indextpl.html && echo '✅ HTML button found' || echo '❌ HTML button NOT found'"
echo ""

echo "========================================"
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Open browser to http://$PI_IP/"
echo "2. Hard refresh: Ctrl+F5 (Windows/Linux) or Cmd+Shift+R (Mac)"
echo "3. Look for wave icon (🌊) next to TV icon (📺)"
echo "4. Click wave icon to test toggle"
echo ""
echo "Expected behavior:"
echo "- First click: 'PeppyMeter ON' notification, display switches to blue VU meter"
echo "- Second click: 'PeppyMeter OFF' notification, display switches back to moOde UI"
echo ""
