#!/bin/bash
################################################################################
# COMPLETE SD CARD CONFIGURATION - SSH + WLAN + FIXED IP
# 
# Configures everything on SD card after burning:
# 1. SSH enabled (flag file)
# 2. WLAN configured (wpa_supplicant.conf)
# 3. Fixed IP address (192.168.1.100)
# 4. All persistent and working
#
# Usage: sudo ./configure-sd-complete.sh
################################################################################

set -e

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
else
    echo "❌ SD-Karte nicht gefunden"
    echo "   Bitte SD-Karte einstecken und warten bis sie gemountet ist"
    exit 1
fi

CONFIG_FILE="$SD_MOUNT/config.txt"
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
SSH_FLAG="$SD_MOUNT/ssh"
WPA_FILE="$SD_MOUNT/wpa_supplicant.conf"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 COMPLETE SD CARD CONFIGURATION                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_MOUNT"
echo ""

################################################################################
# STEP 1: ENABLE SSH
################################################################################

echo "=== STEP 1: ENABLE SSH ==="
sudo touch "$SSH_FLAG"
sudo chmod 644 "$SSH_FLAG"
sync
if [ -f "$SSH_FLAG" ]; then
    echo "✅ SSH-Flag erstellt: $SSH_FLAG"
else
    echo "❌ SSH-Flag konnte nicht erstellt werden"
    exit 1
fi
echo ""

################################################################################
# STEP 2: CONFIGURE WLAN
################################################################################

echo "=== STEP 2: CONFIGURE WLAN ==="
echo ""

# Get WLAN credentials
read -p "WLAN SSID (z.B. Tauwi): " WIFI_SSID
read -sp "WLAN Passwort: " WIFI_PASSWORD
echo ""

if [ -z "$WIFI_SSID" ]; then
    echo "⚠️  Keine SSID eingegeben - überspringe WLAN"
    WIFI_SSID=""
else
    # Create wpa_supplicant.conf
    sudo tee "$WPA_FILE" > /dev/null << EOF
country=DE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
}
EOF
    
    sudo chmod 600 "$WPA_FILE"
    echo "✅ WLAN konfiguriert: $WIFI_SSID"
fi
echo ""

################################################################################
# STEP 3: CONFIGURE FIXED IP ADDRESS
################################################################################

echo "=== STEP 3: CONFIGURE FIXED IP ADDRESS ==="
echo ""

# Get IP addresses
read -p "Feste IP für LAN-Kabel (Ethernet) [192.168.1.100]: " ETH_IP
ETH_IP=${ETH_IP:-192.168.1.100}

if [ -n "$WIFI_SSID" ]; then
    read -p "Feste IP für WLAN [192.168.1.101]: " WIFI_IP
    WIFI_IP=${WIFI_IP:-192.168.1.101}
else
    WIFI_IP=""
fi

# Extract network and gateway from Ethernet IP
IFS='.' read -r ip1 ip2 ip3 ip4 <<< "$ETH_IP"
GATEWAY="$ip1.$ip2.$ip3.1"
NETMASK="255.255.255.0"

echo ""
echo "Konfiguration:"
echo "  LAN-Kabel (eth0): $ETH_IP"
if [ -n "$WIFI_IP" ]; then
    echo "  WLAN (wlan0): $WIFI_IP"
fi
echo "  Gateway: $GATEWAY"
echo "  Netmask: $NETMASK"
echo ""

# Create NetworkManager config directory
NM_DIR="$SD_MOUNT/network"
sudo mkdir -p "$NM_DIR"

# Ethernet with fixed IP (LAN cable - HIGHEST PRIORITY)
ETH_FILE="$NM_DIR/Ethernet-fixed.nmconnection"
sudo tee "$ETH_FILE" > /dev/null << EOF
[connection]
id=Ethernet-fixed
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=manual
addresses=$ETH_IP/24
gateway=$GATEWAY
dns=$GATEWAY;8.8.8.8

[ipv6]
method=auto
EOF
echo "✅ LAN-Kabel (Ethernet) mit fester IP konfiguriert: $ETH_IP"

# WLAN with fixed IP (if WLAN configured)
if [ -n "$WIFI_SSID" ] && [ -n "$WIFI_IP" ]; then
    WIFI_FILE="$NM_DIR/WiFi-fixed.nmconnection"
    sudo tee "$WIFI_FILE" > /dev/null << EOF
[connection]
id=WiFi-fixed
type=wifi
interface-name=wlan0
autoconnect=true
autoconnect-priority=90

[wifi]
mode=infrastructure
ssid=$WIFI_SSID

[wifi-security]
key-mgmt=wpa-psk
psk=$WIFI_PASSWORD

[ipv4]
method=manual
addresses=$WIFI_IP/24
gateway=$GATEWAY
dns=$GATEWAY;8.8.8.8

[ipv6]
method=auto
EOF
    echo "✅ WLAN mit fester IP konfiguriert: $WIFI_IP"
fi
echo ""

################################################################################
# STEP 4: VERIFY ALL CONFIGURATIONS
################################################################################

echo "=== STEP 4: VERIFICATION ==="
echo ""

# Check SSH
if [ -f "$SSH_FLAG" ]; then
    echo "✅ SSH: Aktiviert"
else
    echo "❌ SSH: Fehlt"
fi

# Check WLAN
if [ -f "$WPA_FILE" ] && [ -n "$WIFI_SSID" ]; then
    echo "✅ WLAN: Konfiguriert ($WIFI_SSID)"
elif [ -n "$WIFI_SSID" ]; then
    echo "❌ WLAN: Fehlt"
else
    echo "⚠️  WLAN: Nicht konfiguriert"
fi

# Check Fixed IP
if [ -f "$ETH_FILE" ]; then
    echo "✅ Feste IP: $FIXED_IP"
else
    echo "❌ Feste IP: Fehlt"
fi

sync
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ KONFIGURATION ABGESCHLOSSEN                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Zusammenfassung:"
echo "  - SSH: Aktiviert"
echo "  - LAN-Kabel: $ETH_IP (eth0)"
if [ -n "$WIFI_SSID" ] && [ -n "$WIFI_IP" ]; then
    echo "  - WLAN: $WIFI_SSID → $WIFI_IP (wlan0)"
fi
echo ""
echo "Nächste Schritte:"
echo "  1. SD-Karte sicher auswerfen"
echo "  2. SD-Karte in Raspberry Pi 5 einstecken"
echo "  3. LAN-Kabel einstecken (falls noch nicht)"
echo "  4. Pi booten"
echo "  5. Warte 30-60 Sekunden"
echo ""
echo "Verbindung:"
echo "  LAN-Kabel: ssh pi@$ETH_IP"
if [ -n "$WIFI_IP" ]; then
    echo "  WLAN: ssh pi@$WIFI_IP"
fi
echo "  Web-UI: http://$ETH_IP"
echo ""

