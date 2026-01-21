#!/bin/bash
# Set PeppyMeter to always use blue skin
# Run on Pi: sudo bash set-peppymeter-blue.sh

PEPPY_CONFIG="/etc/peppymeter/config.txt"

echo "Setting PeppyMeter to blue skin..."

if [ ! -f "$PEPPY_CONFIG" ]; then
    echo "❌ PeppyMeter config not found: $PEPPY_CONFIG"
    exit 1
fi

# Set meter to blue
sed -i 's/^meter =.*/meter = blue/' "$PEPPY_CONFIG"

# Disable random meter switching (set to 0 or comment out)
sed -i 's/^random.meter.interval =.*/random.meter.interval = 0/' "$PEPPY_CONFIG"

# Verify changes
if grep -q "^meter = blue" "$PEPPY_CONFIG"; then
    echo "✅ Meter set to blue"
else
    echo "⚠️  Could not verify meter = blue"
fi

if grep -q "^random.meter.interval = 0" "$PEPPY_CONFIG"; then
    echo "✅ Random meter switching disabled"
else
    echo "⚠️  Could not verify random meter disabled"
fi

# Restart PeppyMeter if running
if systemctl is-active --quiet peppymeter.service 2>/dev/null; then
    echo "Restarting PeppyMeter..."
    systemctl restart peppymeter.service
    echo "✅ PeppyMeter restarted"
fi

echo ""
echo "Done! PeppyMeter will now always use blue skin."
