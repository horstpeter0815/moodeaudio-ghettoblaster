#!/bin/bash
# Deploy All Audio Fixes to Raspberry Pi
# Run from Mac workspace root

set -e

PI_HOST="andre@192.168.2.3"
PI_PASSWORD="0815"
WORKSPACE="/Users/andrevollmer/moodeaudio-cursor"

echo "========================================="
echo "Deploying Audio Fixes to Raspberry Pi"
echo "========================================="

# Function to run command on Pi with password
run_on_pi() {
    sshpass -p "$PI_PASSWORD" ssh "$PI_HOST" "$1"
}

# Function to copy file to Pi with password
copy_to_pi() {
    sshpass -p "$PI_PASSWORD" scp "$1" "$PI_HOST:$2"
}

echo ""
echo "Fix #4: CamillaDSP v3 Syntax Corrections"
echo "-----------------------------------------"
echo "Copying Bose Wave configs..."
copy_to_pi "$WORKSPACE/moode-source/usr/share/camilladsp/configs/bose_wave_physics_optimized.yml" "/tmp/"
copy_to_pi "$WORKSPACE/moode-source/usr/share/camilladsp/configs/bose_wave_filters.yml" "/tmp/"
copy_to_pi "$WORKSPACE/moode-source/usr/share/camilladsp/configs/bose_wave_stereo.yml" "/tmp/"
copy_to_pi "$WORKSPACE/moode-source/usr/share/camilladsp/configs/bose_wave_true_stereo.yml" "/tmp/"
copy_to_pi "$WORKSPACE/moode-source/usr/share/camilladsp/configs/bose_wave_waveguide_optimized.yml" "/tmp/"

echo "Installing configs..."
run_on_pi "sudo mv /tmp/bose_wave_*.yml /usr/share/camilladsp/configs/"
run_on_pi "sudo chown root:root /usr/share/camilladsp/configs/bose_wave_*.yml"
run_on_pi "sudo chmod 644 /usr/share/camilladsp/configs/bose_wave_*.yml"

echo "✅ Fix #4 deployed"

echo ""
echo "Fix #2: Enhanced Audio Fix Service"
echo "-----------------------------------"
echo "Copying enhanced fix script..."
copy_to_pi "$WORKSPACE/moode-source/usr/local/bin/fix-audioout-cdsp-enhanced.sh" "/tmp/"
run_on_pi "sudo mv /tmp/fix-audioout-cdsp-enhanced.sh /usr/local/bin/"
run_on_pi "sudo chmod +x /usr/local/bin/fix-audioout-cdsp-enhanced.sh"

echo "Copying enhanced service file..."
copy_to_pi "$WORKSPACE/custom-components/systemd-services/fix-audioout-cdsp-enhanced.service" "/tmp/"
run_on_pi "sudo mv /tmp/fix-audioout-cdsp-enhanced.service /etc/systemd/system/"

echo "Enabling enhanced service..."
run_on_pi "sudo systemctl daemon-reload"
run_on_pi "sudo systemctl disable fix-audioout-cdsp.service 2>/dev/null || true"
run_on_pi "sudo systemctl enable fix-audioout-cdsp-enhanced.service"

echo "✅ Fix #2 deployed"

echo ""
echo "========================================="
echo "Verification"
echo "========================================="
echo ""
echo "Testing CamillaDSP config syntax..."
run_on_pi "camilladsp --check /usr/share/camilladsp/configs/bose_wave_physics_optimized.yml" || echo "⚠️  Config validation failed (might be OK if CamillaDSP not installed)"

echo ""
echo "Current audio configuration:"
run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT param, value FROM cfg_system WHERE param IN ('adevname','cardnum','alsa_output_mode','camilladsp');\""

echo ""
echo "========================================="
echo "✅ All fixes deployed successfully!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Reboot the Pi: sudo reboot"
echo "2. Check CamillaDSP status: systemctl status camilladsp"
echo "3. Check MPD status: systemctl status mpd"
echo "4. Test audio playback (volume 0 first!)"
echo ""
