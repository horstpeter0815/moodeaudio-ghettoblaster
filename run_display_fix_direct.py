#!/usr/bin/env python3
"""
Führt Display-Fix direkt aus - ohne Shell-Abhängigkeit
"""
import subprocess
import sys
import os

def run_command_direct(cmd_list, timeout=120):
    """Führt Befehl direkt aus - ohne Shell"""
    try:
        result = subprocess.run(
            cmd_list,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Timeout"
    except Exception as e:
        return False, "", str(e)

def main():
    print("=== DISPLAY-FIX AUSFÜHRUNG (DIRECT) ===")
    print("")
    
    # Prüfe ob sshpass verfügbar ist
    print("1. Prüfe sshpass...")
    success, stdout, stderr = run_command_direct(["which", "sshpass"])
    if not success:
        print("⚠️  sshpass nicht gefunden")
        print("   Versuche trotzdem mit sshpass-Befehl...")
    else:
        print(f"✅ sshpass gefunden: {stdout.strip()}")
    print("")
    
    # Führe Display-Fix Script direkt auf Pi aus
    print("2. Führe Display-Fix auf Pi aus...")
    
    # Script-Inhalt direkt als SSH-Befehl
    script_content = """set -e
export DISPLAY=:0

echo "=== DISPLAY FIX ==="
echo ""

# Backup
echo "1. Backup..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup.$(date +%Y%m%d_%H%M%S)
[ -f /home/andre/.xinitrc ] && cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup erstellt"
echo ""

# config.txt
echo "2. Setze config.txt..."
sudo tee /boot/firmware/config.txt > /dev/null << 'CONFIG_EOF'
# Moode Audio - Pi 5 - Final Display Configuration
[all]
disable_fw_kms_setup=1
[pi5]
display_rotate=0
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_group=2
hdmi_mode=87
disable_overscan=1
framebuffer_width=1280
framebuffer_height=400
CONFIG_EOF
echo "✅ config.txt gesetzt"
echo ""

# cmdline.txt
echo "3. Setze cmdline.txt..."
CURRENT_CMDLINE=$(cat /boot/firmware/cmdline.txt)
CURRENT_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/video=[^ ]*//g')
NEW_CMDLINE="$CURRENT_CMDLINE video=HDMI-A-2:1280x400M@60"
echo "$NEW_CMDLINE" | sudo tee /boot/firmware/cmdline.txt > /dev/null
echo "✅ cmdline.txt gesetzt"
echo ""

# xinitrc
echo "4. Setze xinitrc..."
cat > /home/andre/.xinitrc << 'XINITRC_EOF'
#!/bin/sh
export DISPLAY=:0
sleep 2
for i in 1 2 3 4 5; do
    if xrandr --output HDMI-A-2 --query 2>/dev/null | grep -q "connected"; then
        break
    fi
    sleep 1
done
xrandr --output HDMI-A-2 --mode 1280x400 2>/dev/null || \\
xrandr --output HDMI-A-2 --mode 400x1280 --rotate right 2>/dev/null || \\
xrandr --output HDMI-A-2 --auto 2>/dev/null
xrandr --fb 1280x400 2>/dev/null || true
exec chromium-browser --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble --disable-restore-session-state --window-size=1280,400 --start-fullscreen http://localhost
XINITRC_EOF
chmod +x /home/andre/.xinitrc
echo "✅ xinitrc gesetzt"
echo ""

# Touchscreen
echo "5. Setze Touchscreen-Config..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'TOUCH_EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
TOUCH_EOF
echo "✅ Touchscreen-Config gesetzt"
echo ""

echo "=== FERTIG ==="
echo "Reboot erforderlich: sudo reboot"
"""
    
    # Führe über SSH aus
    PI_IP = "192.168.178.178"
    PI_USER = "andre"
    PI_PASS = "0815"
    
    # Verwende sshpass wenn verfügbar, sonst ssh mit key
    sshpass_cmd = ["sshpass", "-p", PI_PASS, "ssh", "-o", "StrictHostKeyChecking=no", 
                   "-o", "ConnectTimeout=10", f"{PI_USER}@{PI_IP}", "bash"]
    
    try:
        print("Verbinde mit Pi...")
        process = subprocess.Popen(
            sshpass_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        stdout, stderr = process.communicate(input=script_content, timeout=180)
        
        print(stdout)
        if stderr:
            print("STDERR:", stderr, file=sys.stderr)
        
        if process.returncode == 0:
            print("")
            print("✅ Display-Fix erfolgreich ausgeführt")
            print("")
            print("3. Reboote Pi...")
            
            # Reboot
            reboot_cmd = ["sshpass", "-p", PI_PASS, "ssh", "-o", "StrictHostKeyChecking=no",
                         "-o", "ConnectTimeout=10", f"{PI_USER}@{PI_IP}", "sudo reboot"]
            success, _, _ = run_command_direct(reboot_cmd, timeout=10)
            if success:
                print("✅ Reboot-Befehl gesendet")
            else:
                print("⚠️  Reboot-Befehl (Pi könnte trotzdem rebooten)")
            
            print("")
            print("=== FERTIG ===")
            print("Pi wird rebootet. Warte 1-2 Minuten.")
            return 0
        else:
            print(f"❌ Display-Fix fehlgeschlagen (Exit Code: {process.returncode})")
            return 1
            
    except FileNotFoundError:
        print("❌ sshpass nicht gefunden")
        print("Bitte installiere sshpass:")
        print("  brew install hudochenkov/sshpass/sshpass")
        return 1
    except subprocess.TimeoutExpired:
        print("❌ Timeout beim Ausführen")
        return 1
    except Exception as e:
        print(f"❌ Fehler: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

