#!/bin/bash
# Verify CamillaDSP activation status

echo "=== Verifying CamillaDSP Activation ==="
echo ""

echo "1. CamillaDSP Process:"
if pgrep -x camilladsp > /dev/null; then
    echo "   ✓ CamillaDSP is RUNNING (PID: $(pgrep -x camilladsp))"
else
    echo "   ✗ CamillaDSP is NOT running"
fi
echo ""

echo "2. Database Status:"
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null | while read config; do
    if [ "$config" = "bose_wave_filters.yml" ]; then
        echo "   ✓ Config in database: $config"
    else
        echo "   ✗ Config in database: $config (expected: bose_wave_filters.yml)"
    fi
done
echo ""

echo "3. MPD Mixer Type:"
MIXER_TYPE=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_mpd WHERE param='mixer_type';" 2>/dev/null)
if [ "$MIXER_TYPE" = "null" ]; then
    echo "   ✓ Mixer type: $MIXER_TYPE (CamillaDSP volume control)"
else
    echo "   ✗ Mixer type: $MIXER_TYPE (expected: null)"
fi
echo ""

echo "4. Config File:"
if [ -f "/usr/share/camilladsp/configs/bose_wave_filters.yml" ]; then
    echo "   ✓ Config file exists"
    echo "   $(ls -lh /usr/share/camilladsp/configs/bose_wave_filters.yml | awk '{print "   Size:", $5, "Modified:", $6, $7, $8}')"
else
    echo "   ✗ Config file NOT found"
fi
echo ""

echo "5. CamillaDSP Service Status:"
if systemctl is-active --quiet mpd2cdspvolume; then
    echo "   ✓ mpd2cdspvolume service is ACTIVE"
else
    echo "   ✗ mpd2cdspvolume service is NOT active"
fi
echo ""

echo "6. MPD Status:"
if systemctl is-active --quiet mpd; then
    echo "   ✓ MPD is RUNNING"
    echo "   $(systemctl status mpd --no-pager -l | grep -E 'Active:|Main PID:' | head -2)"
else
    echo "   ✗ MPD is NOT running"
fi
echo ""

echo "7. Worker Log (last 20 lines related to camilladsp):"
tail -100 /var/log/moode.log 2>/dev/null | grep -i "camilladsp\|cdsp\|mixer" | tail -20 || echo "   (no relevant logs found)"
echo ""

echo "=== Verification Complete ==="

