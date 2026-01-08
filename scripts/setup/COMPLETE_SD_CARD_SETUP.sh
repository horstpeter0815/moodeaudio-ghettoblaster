#!/bin/bash
################################################################################
#
# COMPLETE SD CARD SETUP - ALLES AUF EINMAL
#
# Konfiguriert: SSH, WLAN, Display, Rotation, Network
# Auf SD-Karte die im Mac ist
#
################################################################################

set -e

# Finde SD-Karte
SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
else
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 COMPLETE SD CARD SETUP                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_MOUNT"
echo ""

# 1. SSH aktivieren
echo "1. SSH aktivieren..."
rm -rf "$SD_MOUNT/ssh" 2>/dev/null || true
touch "$SD_MOUNT/ssh"
echo "✅ SSH aktiviert"
echo ""

# 2. WLAN konfigurieren
echo "2. WLAN konfigurieren..."
tee "$SD_MOUNT/wpa_supplicant.conf" > /dev/null << 'EOF'
country=DE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="TAVEE-II"
    psk="D76DE8F2CF"
}
EOF
chmod 600 "$SD_MOUNT/wpa_supplicant.conf"
echo "✅ WLAN konfiguriert (TAVEE-II)"
echo ""

# 3. config.txt - Display Rotation
echo "3. config.txt - Display Rotation..."
cp "$SD_MOUNT/config.txt" "$SD_MOUNT/config.txt.backup"

# Prüfe ob [pi5] Section existiert
if grep -q "\[pi5\]" "$SD_MOUNT/config.txt"; then
    # Setze display_rotate=2 in [pi5] Section
    awk '
    /\[pi5\]/ { 
        print; 
        in_pi5=1; 
        next 
    }
    /^\[/ { 
        in_pi5=0 
    }
    in_pi5 && /^display_rotate=/ { 
        print "display_rotate=2"; 
        next 
    }
    in_pi5 && /^\[/ { 
        print "display_rotate=2"; 
        print; 
        next 
    }
    { print }
    END {
        if (in_pi5) {
            print "display_rotate=2"
        }
    }' "$SD_MOUNT/config.txt" > "$SD_MOUNT/config.txt.tmp"
    
    # Füge display_rotate=2 hinzu wenn nicht vorhanden
    if ! grep -q "display_rotate=2" "$SD_MOUNT/config.txt.tmp"; then
        sed -i.bak '/\[pi5\]/a\
display_rotate=2
' "$SD_MOUNT/config.txt.tmp"
    fi
    
    mv "$SD_MOUNT/config.txt.tmp" "$SD_MOUNT/config.txt"
else
    # Füge [pi5] Section mit display_rotate=2 hinzu
    echo "" >> "$SD_MOUNT/config.txt"
    echo "[pi5]" >> "$SD_MOUNT/config.txt"
    echo "display_rotate=2" >> "$SD_MOUNT/config.txt"
fi

echo "✅ display_rotate=2 gesetzt"
echo ""

# 4. cmdline.txt - Rotation
echo "4. cmdline.txt - Rotation..."
cp "$SD_MOUNT/cmdline.txt" "$SD_MOUNT/cmdline.txt.backup"
CMDLINE=$(cat "$SD_MOUNT/cmdline.txt")

# Entferne alte Rotation-Parameter
CMDLINE=$(echo "$CMDLINE" | sed 's/fbcon=rotate:[0-9]//g' | sed 's/video=HDMI-A-[0-9]:[^ ]*//g')

# Füge neue Parameter hinzu
if ! echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
    CMDLINE="$CMDLINE fbcon=rotate:3"
fi
if ! echo "$CMDLINE" | grep -q "video=HDMI-A-2:400x1280M@60,rotate=90"; then
    CMDLINE="$CMDLINE video=HDMI-A-2:400x1280M@60,rotate=90"
fi

echo "$CMDLINE" | tee "$SD_MOUNT/cmdline.txt" > /dev/null
echo "✅ cmdline.txt konfiguriert (fbcon=rotate:3, video=HDMI-A-2)"
echo ""

# 5. Network-Config
echo "5. Network-Config (statische IP 192.168.10.2)..."
tee "$SD_MOUNT/network-config" > /dev/null << 'EOF'
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.10.2/24
      gateway4: 192.168.10.1
      nameservers:
        addresses:
          - 192.168.10.1
          - 8.8.8.8
  wifis:
    wlan0:
      dhcp4: true
      optional: true
EOF
echo "✅ Network-Config erstellt"
echo ""

# Sync
sync

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ALLES KONFIGURIERT!                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Zusammenfassung:"
echo "  ✅ SSH aktiviert"
echo "  ✅ WLAN konfiguriert (TAVEE-II)"
echo "  ✅ Display Rotation (display_rotate=2 in [pi5])"
echo "  ✅ cmdline.txt Rotation (fbcon=rotate:3, video=HDMI-A-2)"
echo "  ✅ Network-Config (192.168.10.2)"
echo ""
echo "SD-Karte kann jetzt ausgeworfen werden."
echo ""

