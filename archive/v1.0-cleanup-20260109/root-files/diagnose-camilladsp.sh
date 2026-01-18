#!/bin/bash
# Diagnose why CamillaDSP isn't starting

echo "=== CamillaDSP Diagnosis ==="
echo ""

echo "1. _audioout.conf (should point to 'camilladsp'):"
cat /etc/alsa/conf.d/_audioout.conf
echo ""

echo "2. Session camilladsp value:"
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null
echo ""

echo "3. working_config.yml symlink:"
ls -la /usr/share/camilladsp/working_config.yml 2>/dev/null || echo "   NOT FOUND"
echo ""

echo "4. ALSA camilladsp device test:"
timeout 2 aplay -D camilladsp /dev/zero 2>&1 | head -5 || echo "   Failed to open camilladsp device"
echo ""

echo "5. CamillaDSP process:"
ps aux | grep camilladsp | grep -v grep || echo "   NOT RUNNING"
echo ""

echo "6. Check if MPD is trying to use camilladsp:"
grep -i "camilladsp\|_audioout" /var/log/mpd/log 2>/dev/null | tail -10 || echo "   (no relevant logs)"
echo ""

echo "=== Diagnosis Complete ==="

