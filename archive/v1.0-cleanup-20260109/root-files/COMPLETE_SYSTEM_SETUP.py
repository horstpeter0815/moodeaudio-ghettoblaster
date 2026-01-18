#!/usr/bin/env python3
"""
Komplettes System-Setup für Moode Audio Pi 5
- Display-Konfiguration
- Touchscreen-Setup
- Video-Pipeline-Verifikation
- Dokumentation
"""
import subprocess
import sys
import os
import time
import socket

PI_USER = "andre"
PI_PASS = "0815"
PI_HOSTNAME = "ghettopi5"
KNOWN_IPS = ["192.168.178.162", "192.168.178.178", "192.168.178.143"]

# Finde sshpass
SSHPASS_PATH = None
for path in ["/opt/homebrew/bin/sshpass", "/usr/local/bin/sshpass", "sshpass"]:
    if os.path.exists(path) or path == "sshpass":
        SSHPASS_PATH = path
        break

def find_pi():
    """Findet den Pi über Hostname oder bekannte IPs"""
    print("=== FINDE RASPBERRY PI ===")
    print("")
    
    # Versuche Hostname
    try:
        ip = socket.gethostbyname(PI_HOSTNAME)
        if ping_test(ip):
            print(f"✅ Pi gefunden via Hostname: {ip}")
            return ip
    except:
        pass
    
    # Versuche bekannte IPs
    for ip in KNOWN_IPS:
        if ping_test(ip):
            print(f"✅ Pi gefunden: {ip}")
            return ip
    
    return None

def ping_test(ip):
    """Testet ob Pi erreichbar ist"""
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "2", ip],
            capture_output=True,
            timeout=5
        )
        return result.returncode == 0
    except:
        return False

def wait_for_pi(ip, max_wait=120):
    """Wartet bis Pi online ist"""
    print(f"Warte auf Pi ({ip})...")
    for i in range(max_wait):
        if ping_test(ip):
            print(f"✅ Pi ist online (nach {i} Sekunden)")
            time.sleep(5)  # Warte auf vollständigen Boot
            return True
        time.sleep(1)
        if i % 10 == 0:
            print(f"   ... {i}/{max_wait} Sekunden")
    return False

def execute_remote(ip, script, description):
    """Führt Script auf Pi aus"""
    print(f"\n=== {description} ===")
    print("")
    
    ssh_cmd = [SSHPASS_PATH, "-p", PI_PASS, "ssh", "-o", "StrictHostKeyChecking=no",
              "-o", "ConnectTimeout=10", f"{PI_USER}@{ip}", "bash"]
    
    try:
        p = subprocess.Popen(ssh_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, text=True, env=os.environ.copy())
        stdout, stderr = p.communicate(input=script, timeout=300)
        
        if stdout:
            print(stdout)
        if stderr and "Warning" not in stderr:
            print(f"STDERR: {stderr}", file=sys.stderr)
        
        return p.returncode == 0
    except subprocess.TimeoutExpired:
        print("❌ Timeout beim Ausführen")
        return False
    except Exception as e:
        print(f"❌ Fehler: {e}")
        return False

def setup_display_config(ip):
    """Konfiguriert Display vollständig"""
    script = """#!/bin/bash
set -e

echo "=== DISPLAY-KONFIGURATION ==="
echo ""

# Remount /boot/firmware als READ-WRITE
echo "1. Remount /boot/firmware..."
sudo mount -o remount,rw /boot/firmware

# Backup config.txt
echo "2. Erstelle Backup..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup_$(date +%Y%m%d_%H%M%S)

# Konfiguriere config.txt
echo "3. Konfiguriere config.txt..."
sudo tee /boot/firmware/config.txt > /dev/null << 'EOF'
# Moode Audio - Pi 5 - Display Configuration
# Waveshare 7.9" HDMI - 1280x400 Landscape

[all]
# Disable firmware KMS setup - verwende True KMS
disable_fw_kms_setup=1

# Framebuffer
framebuffer_width=1280
framebuffer_height=400

[pi5]
# Display Rotation - 0 = normal (landscape)
display_rotate=0

# HDMI Configuration
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_group=2
hdmi_mode=87

# Disable Overscan
disable_overscan=1
EOF

# Konfiguriere cmdline.txt
echo "4. Konfiguriere cmdline.txt..."
if ! grep -q "video=HDMI-A-2:1280x400M@60" /boot/firmware/cmdline.txt; then
    sudo sed -i 's/$/ video=HDMI-A-2:1280x400M@60/' /boot/firmware/cmdline.txt
fi

# Sync
echo "5. Sync..."
sync

echo ""
echo "✅ Display-Konfiguration abgeschlossen"
"""

    return execute_remote(ip, script, "DISPLAY-KONFIGURATION")

def setup_x11_and_chromium(ip):
    """Konfiguriert X11 und Chromium"""
    script = """#!/bin/bash
set -e

echo "=== X11 UND CHROMIUM KONFIGURATION ==="
echo ""

# Erstelle .xinitrc
echo "1. Erstelle .xinitrc..."
sudo tee /home/andre/.xinitrc > /dev/null << 'EOF'
#!/bin/sh
# Moode Audio - X11 Startup Script
# Display: 1280x400 Landscape

# Warte auf X11
sleep 2

# Setze Display-Variablen
export DISPLAY=:0

# Warte auf HDMI-2
for i in 1 2 3 4 5; do
    if xrandr --output HDMI-2 --query 2>/dev/null | grep -q "connected"; then
        break
    fi
    sleep 1
done

# Setze Display-Modus (1280x400)
xrandr --output HDMI-2 --mode 1280x400 2>/dev/null || \\
xrandr --output HDMI-2 --mode 400x1280 --rotate right 2>/dev/null || \\
xrandr --output HDMI-2 --auto 2>/dev/null

# Setze Framebuffer-Größe
xrandr --fb 1280x400 2>/dev/null || true

# Starte Chromium in Kiosk-Mode
exec chromium-browser \\
    --kiosk \\
    --noerrdialogs \\
    --disable-infobars \\
    --disable-session-crashed-bubble \\
    --disable-restore-session-state \\
    --window-size=1280,400 \\
    --start-fullscreen \\
    http://localhost
EOF

# Setze Berechtigungen
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod 755 /home/andre/.xinitrc

echo "✅ X11/Chromium-Konfiguration abgeschlossen"
"""

    return execute_remote(ip, script, "X11 UND CHROMIUM")

def setup_touchscreen(ip):
    """Konfiguriert Touchscreen"""
    script = """#!/bin/bash
set -e

echo "=== TOUCHSCREEN-KONFIGURATION ==="
echo ""

# Erstelle Verzeichnis
sudo mkdir -p /etc/X11/xorg.conf.d

# Erstelle Touchscreen-Config
echo "1. Erstelle Touchscreen-Config..."
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
EOF

echo "✅ Touchscreen-Konfiguration abgeschlossen"
"""

    return execute_remote(ip, script, "TOUCHSCREEN-KONFIGURATION")

def run_video_test(ip):
    """Führt Video-Pipeline-Test aus"""
    # Lese Test-Script
    test_script_path = "VIDEO_PIPELINE_TEST_SAFE.sh"
    if not os.path.exists(test_script_path):
        print(f"⚠️  Test-Script nicht gefunden: {test_script_path}")
        return False
    
    with open(test_script_path, 'r') as f:
        test_script = f.read()
    
    # Kopiere Test-Script auf Pi
    print("\n=== KOPIERE TEST-SCRIPT ===")
    scp_cmd = [SSHPASS_PATH, "-p", PI_PASS, "scp", "-o", "StrictHostKeyChecking=no",
               test_script_path, f"{PI_USER}@{ip}:/tmp/"]
    
    try:
        result = subprocess.run(scp_cmd, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            print(f"⚠️  Fehler beim Kopieren: {result.stderr}")
            return False
        print("✅ Test-Script kopiert")
    except Exception as e:
        print(f"❌ Fehler: {e}")
        return False
    
    # Führe Test aus
    script = """#!/bin/bash
chmod +x /tmp/VIDEO_PIPELINE_TEST_SAFE.sh
/tmp/VIDEO_PIPELINE_TEST_SAFE.sh
"""
    
    return execute_remote(ip, script, "VIDEO-PIPELINE-TEST")

def verify_system(ip):
    """Verifiziert System-Konfiguration"""
    script = """#!/bin/bash
echo "=== SYSTEM-VERIFIKATION ==="
echo ""

echo "1. config.txt:"
grep -E "display_rotate|hdmi_mode|disable_fw_kms_setup|framebuffer" /boot/firmware/config.txt || echo "  Keine relevanten Einträge"

echo ""
echo "2. cmdline.txt video= Parameter:"
grep "video=" /boot/firmware/cmdline.txt || echo "  Kein video= Parameter"

echo ""
echo "3. .xinitrc vorhanden:"
[[ -f /home/andre/.xinitrc ]] && echo "  ✅ Vorhanden" || echo "  ❌ Fehlt"

echo ""
echo "4. Touchscreen-Config vorhanden:"
[[ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]] && echo "  ✅ Vorhanden" || echo "  ❌ Fehlt"

echo ""
echo "5. X11 Status:"
pgrep -x Xorg > /dev/null && echo "  ✅ X11 läuft" || echo "  ❌ X11 läuft nicht"

echo ""
echo "6. Chromium Status:"
pgrep -f chromium-browser > /dev/null && echo "  ✅ Chromium läuft" || echo "  ❌ Chromium läuft nicht"

echo ""
echo "7. Display Status:"
export DISPLAY=:0
xrandr --output HDMI-2 --query 2>/dev/null | grep -E "connected|current" || echo "  Display nicht erkannt"

echo ""
echo "✅ Verifikation abgeschlossen"
"""

    return execute_remote(ip, script, "SYSTEM-VERIFIKATION")

def main():
    print("=" * 60)
    print("KOMPLETTES SYSTEM-SETUP FÜR MOODE AUDIO PI 5")
    print("=" * 60)
    print("")
    
    # Finde Pi
    pi_ip = find_pi()
    if not pi_ip:
        print("❌ Pi nicht gefunden")
        print("Versuche bekannte IPs...")
        for ip in KNOWN_IPS:
            print(f"Prüfe {ip}...")
            if ping_test(ip):
                pi_ip = ip
                break
        
        if not pi_ip:
            print("❌ Pi nicht erreichbar")
            return 1
    
    print(f"\n✅ Arbeite mit Pi: {pi_ip}")
    print("")
    
    # Warte auf Pi falls nötig
    if not ping_test(pi_ip):
        if not wait_for_pi(pi_ip):
            print("❌ Pi nicht erreichbar nach Wartezeit")
            return 1
    
    # Setup-Schritte
    steps = [
        ("Display-Konfiguration", setup_display_config),
        ("X11 und Chromium", setup_x11_and_chromium),
        ("Touchscreen", setup_touchscreen),
    ]
    
    for step_name, step_func in steps:
        if not step_func(pi_ip):
            print(f"❌ Fehler bei: {step_name}")
            return 1
        time.sleep(2)
    
    # Verifikation
    print("\n" + "=" * 60)
    print("VERIFIKATION")
    print("=" * 60)
    verify_system(pi_ip)
    
    # Video-Test
    print("\n" + "=" * 60)
    print("VIDEO-PIPELINE-TEST")
    print("=" * 60)
    run_video_test(pi_ip)
    
    print("\n" + "=" * 60)
    print("SETUP ABGESCHLOSSEN")
    print("=" * 60)
    print("")
    print("Nächste Schritte:")
    print("1. Pi rebooten: sudo reboot")
    print("2. Nach Reboot verifizieren")
    print("3. Video-Test erneut ausführen")
    print("")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

