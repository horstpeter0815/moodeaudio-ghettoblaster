#!/bin/bash
################################################################################
# CONFIGURE NETWORK ON SD CARD - WITH PRE-SET VALUES
# 
# Configures WLAN and Fixed IP directly on SD card
# Usage: sudo ./configure-network-now.sh
################################################################################

set -e

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
else
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

WIFI_SSID="TAVEE-II"
WIFI_PASSWORD="D76DE8F2CF"
# ⚠️ WICHTIG: 192.168.1.101 ist der FREMDE WLAN-ROUTER, NICHT der Pi!
# Verwende stattdessen Direct LAN (192.168.10.2) oder eine andere IP
ETH_IP="192.168.10.2"  # Direct LAN (Mac ↔ Pi)
WIFI_IP="192.168.1.100"  # WLAN IP (falls Router vorhanden, NICHT .101!)
GATEWAY="192.168.10.1"  # Mac IP für Direct LAN

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 CONFIGURE NETWORK ON SD CARD                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_MOUNT"
echo "WLAN: $WIFI_SSID"
echo "LAN IP: $ETH_IP"
echo "WLAN IP: $WIFI_IP"
echo ""

################################################################################
# STEP 1: ENABLE SSH
################################################################################

echo "=== STEP 1: ENABLE SSH ==="
sudo rm -rf "$SD_MOUNT/ssh" 2>/dev/null || true
sudo sh -c "echo '' > '$SD_MOUNT/ssh' && chmod 644 '$SD_MOUNT/ssh'"
sync
if sudo test -f "$SD_MOUNT/ssh"; then
    echo "✅ SSH-Flag erstellt"
else
    echo "❌ SSH-Flag konnte nicht erstellt werden"
    exit 1
fi
echo ""

################################################################################
# STEP 2: CONFIGURE WLAN
################################################################################

echo "=== STEP 2: CONFIGURE WLAN ==="

# Create wpa_supplicant.conf
sudo tee "$SD_MOUNT/wpa_supplicant.conf" > /dev/null << EOF
country=DE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
}
EOF

sudo chmod 600 "$SD_MOUNT/wpa_supplicant.conf"
echo "✅ WLAN konfiguriert: $WIFI_SSID"
echo ""

################################################################################
# STEP 3: CONFIGURE FIXED IP ADDRESS
################################################################################

echo "=== STEP 3: CONFIGURE FIXED IP ADDRESS ==="

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

# WLAN with fixed IP
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
echo ""

################################################################################
# STEP 4: VERIFY
################################################################################

echo "=== STEP 4: VERIFICATION ==="
echo ""

if sudo test -f "$SD_MOUNT/ssh"; then
    echo "✅ SSH: Aktiviert"
else
    echo "❌ SSH: Fehlt"
fi

if sudo test -f "$SD_MOUNT/wpa_supplicant.conf"; then
    echo "✅ WLAN: Konfiguriert ($WIFI_SSID)"
else
    echo "❌ WLAN: Fehlt"
fi

if sudo test -f "$ETH_FILE"; then
    echo "✅ LAN IP: $ETH_IP"
else
    echo "❌ LAN IP: Fehlt"
fi

if sudo test -f "$WIFI_FILE"; then
    echo "✅ WLAN IP: $WIFI_IP"
else
    echo "❌ WLAN IP: Fehlt"
fi

sync
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ NETZWERK KONFIGURIERT                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Zusammenfassung:"
echo "  - SSH: Aktiviert"
echo "  - WLAN: $WIFI_SSID"
echo "  - LAN-Kabel: $ETH_IP (eth0)"
echo "  - WLAN: $WIFI_IP (wlan0)"
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
echo "  WLAN: ssh pi@$WIFI_IP"
echo "  Web-UI: http://$ETH_IP"
echo ""

