#!/bin/bash
# Test and verify Bose Wave filters on moOde Pi system
# Run this ON THE PI SYSTEM

echo "=== Testing Bose Wave Filters on moOde ==="
echo ""

# Check if file exists
CONFIG_FILE="/usr/share/camilladsp/configs/bose_wave_filters.yml"
echo "1. Checking if config file exists..."
if [ -f "$CONFIG_FILE" ]; then
    echo "   ✅ File exists: $CONFIG_FILE"
    ls -lh "$CONFIG_FILE"
else
    echo "   ❌ File NOT found: $CONFIG_FILE"
    exit 1
fi

echo ""
echo "2. Checking file permissions..."
PERMS=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
echo "   Permissions: $PERMS"
if [ "$PERMS" = "644" ] || [ "$PERMS" = "0664" ]; then
    echo "   ✅ Permissions OK"
else
    echo "   ⚠️  Permissions might need to be 644"
fi

echo ""
echo "3. Validating config file with CamillaDSP..."
if command -v camilladsp >/dev/null 2>&1; then
    camilladsp -c "$CONFIG_FILE" 2>&1 | head -20
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        echo "   ✅ Config file is valid!"
    else
        echo "   ❌ Config file has errors (exit code: $EXIT_CODE)"
        echo "   Run: camilladsp -c $CONFIG_FILE"
    fi
else
    echo "   ⚠️  camilladsp command not found - cannot validate"
fi

echo ""
echo "4. Checking if moOde can see the config..."
echo "   Listing all config files:"
ls -1 /usr/share/camilladsp/configs/*.yml 2>/dev/null | while read f; do
    echo "   - $(basename "$f")"
done

echo ""
echo "5. Checking CamillaDSP status..."
if pgrep -x camilladsp > /dev/null; then
    echo "   ✅ CamillaDSP is running"
    echo "   PID: $(pgrep -x camilladsp)"
else
    echo "   ⚠️  CamillaDSP is not running"
fi

echo ""
echo "6. Checking current CamillaDSP config..."
if [ -f "/etc/alsa/conf.d/camilladsp.conf" ]; then
    echo "   ALSA config exists"
    grep -i "config" /etc/alsa/conf.d/camilladsp.conf 2>/dev/null | head -5
fi

echo ""
echo "=== Summary ==="
echo "To use the filters:"
echo "1. Go to moOde web interface"
echo "2. Audio Config → CamillaDSP → Signal processing"
echo "3. Select 'bose_wave_filters' from dropdown"
echo "4. Click Apply"
echo ""
echo "Or via CamillaDSP Config page:"
echo "1. CamillaDSP Config → Signal processing dropdown"
echo "2. Select 'bose_wave_filters'"
echo "3. Click Apply"


