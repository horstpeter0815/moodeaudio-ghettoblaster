#!/bin/bash
#
# Step-by-step audio diagnosis
# DO NOT APPLY FIXES - JUST DIAGNOSE
#

echo "=== STEP-BY-STEP AUDIO DIAGNOSIS ==="
echo ""
echo "STEP 1: Check current audio configuration"
echo "----------------------------------------"
echo ""
echo "1.1 Database audio settings:"
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT param, value FROM cfg_system WHERE param LIKE '%audio%' OR param LIKE '%alsa%' OR param IN ('adevname', 'cardnum');" 2>/dev/null
echo ""
echo "1.2 MPD configuration:"
echo "   Device:"
grep "^audio_output" /etc/mpd.conf | head -3
grep "^[[:space:]]*device" /etc/mpd.conf | head -1
echo ""
echo "   Mixer:"
grep "^[[:space:]]*mixer_device\|^[[:space:]]*mixer_control" /etc/mpd.conf | head -2
echo ""
echo "1.3 ALSA configuration:"
if [ -f /etc/alsa/conf.d/_audioout.conf ]; then
    echo "   _audioout.conf:"
    cat /etc/alsa/conf.d/_audioout.conf
else
    echo "   _audioout.conf not found"
fi
echo ""
echo "STEP 2: Check audio hardware detection"
echo "----------------------------------------"
echo ""
echo "2.1 ALSA cards:"
aplay -l 2>/dev/null || echo "  aplay -l failed"
echo ""
echo "2.2 ALSA devices:"
cat /proc/asound/cards 2>/dev/null || echo "  Cannot read /proc/asound/cards"
echo ""
echo "2.3 HiFiBerry AMP100 detection:"
dmesg | grep -i "hifiberry\|amp100\|snd.*hifiberry" | tail -10
echo ""
echo "STEP 3: Check MPD status"
echo "----------------------------------------"
echo ""
echo "3.1 MPD service status:"
systemctl is-active mpd >/dev/null 2>&1 && echo "  ✓ MPD: ACTIVE" || echo "  ✗ MPD: NOT ACTIVE"
echo ""
echo "3.2 MPD audio output:"
mpc outputs 2>/dev/null || echo "  mpc outputs failed"
echo ""
echo "3.3 MPD current device:"
mpc status 2>/dev/null | head -5 || echo "  mpc status failed"
echo ""
echo "STEP 4: Check for IEC 958 references"
echo "----------------------------------------"
echo ""
echo "4.1 MPD config IEC 958:"
grep -i "iec\|958\|spdif" /etc/mpd.conf | head -5
echo ""
echo "4.2 ALSA IEC 958:"
grep -r "iec\|958\|spdif" /etc/alsa/conf.d/ 2>/dev/null | head -5
echo ""
echo "STEP 5: Current audio information"
echo "----------------------------------------"
echo ""
echo "5.1 What does moOde show in Audio Information?"
echo "   (This would show if IEC 958 device appears)"
echo ""
echo "=== DIAGNOSIS COMPLETE ==="
echo ""
echo "Next steps: Based on findings, we'll fix audio step by step"
echo ""
