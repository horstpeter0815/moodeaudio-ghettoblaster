#!/usr/bin/env python3
import subprocess
import sys
import time

PI_IP = "192.168.178.178"
PI_USER = "andre"
PI_PASS = "0815"

def run_ssh(cmd):
    ssh_cmd = [
        "sshpass", "-p", PI_PASS,
        "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=10",
        f"{PI_USER}@{PI_IP}",
        cmd
    ]
    try:
        result = subprocess.run(ssh_cmd, capture_output=True, text=True, timeout=30)
        return result.stdout, result.stderr, result.returncode
    except Exception as e:
        return "", str(e), 1

print("=== FIXE PORTRAIT-MODUS JETZT ===")
print()

# 1. Prüfe aktuelle Situation
print("1. Prüfe Display-Status...")
stdout, stderr, code = run_ssh("export DISPLAY=:0 && xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E 'current|rotation' | head -2")
print(stdout)

# 2. Finde Modus
print("2. Finde verfügbaren Modus...")
stdout, stderr, code = run_ssh("xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E '^\\s+[0-9]+x[0-9]+' | awk '{print $1}' | head -1")
mode = stdout.strip()
print(f"   Modus: {mode}")

# 3. Wende Rotation sofort an
print("3. Wende Rotation sofort an...")
fix_cmd = f"""
export DISPLAY=:0
xrandr --output HDMI-A-2 --mode {mode} --rotate right 2>&1
sleep 1
xrandr --fb 1280x400 2>&1
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E 'current|rotation' | head -2
"""
stdout, stderr, code = run_ssh(f"bash -c '{fix_cmd}'")
print(stdout)

# 4. Fixe xinitrc
print("4. Fixe xinitrc...")
fix_xinitrc = f"""
cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
sed -i '/xrandr.*HDMI-A-2/d' /home/andre/.xinitrc 2>/dev/null || true
if grep -q "chromium" /home/andre/.xinitrc; then
    sed -i "/chromium/i xrandr --output HDMI-A-2 --mode {mode} --rotate right" /home/andre/.xinitrc
    sed -i "/chromium/i xrandr --fb 1280x400" /home/andre/.xinitrc
    sed -i "/chromium/i sleep 2" /home/andre/.xinitrc
else
    echo "xrandr --output HDMI-A-2 --mode {mode} --rotate right" >> /home/andre/.xinitrc
    echo "xrandr --fb 1280x400" >> /home/andre/.xinitrc
fi
echo "✅ xinitrc gefixt"
grep "xrandr.*HDMI-A-2" /home/andre/.xinitrc | head -3
"""
stdout, stderr, code = run_ssh(f"bash -c '{fix_xinitrc}'")
print(stdout)

# 5. Fixe Touchscreen
print("5. Fixe Touchscreen Matrix...")
fix_touch = """
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'TOUCH'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
EndSection
TOUCH
echo "✅ Touchscreen Matrix gesetzt"
"""
stdout, stderr, code = run_ssh(f"bash -c '{fix_touch}'")
print(stdout)

# 6. Verifiziere
print("6. Verifiziere Rotation...")
verify = """
export DISPLAY=:0
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E 'current|rotation' | head -2
xdpyinfo 2>/dev/null | grep dimensions | head -1
"""
stdout, stderr, code = run_ssh(f"bash -c '{verify}'")
print(stdout)

print()
print("✅ ROTATION GEFIXT - Display sollte jetzt Landscape sein")

