#!/bin/bash
################################################################################
#
# CONFIGURE WLAN ON PI VIA LAN CABLE
#
# Konfiguriert WLAN auf dem Pi über LAN-Kabel-Verbindung
#
################################################################################

PI_IP="192.168.10.2"
PI_USER="pi"
PI_PASS="moodeaudio"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📶 WLAN AUF PI KONFIGURIEREN (VIA LAN)                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Pi erreichbar ist
echo "🔍 Prüfe Verbindung zum Pi..."
if ! ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
    echo "❌ Pi nicht erreichbar: $PI_IP"
    echo "   Bitte zuerst ausführen: ./CONFIGURE_MAC_ETHERNET_FOR_PI.sh"
    exit 1
fi

echo "✅ Pi erreichbar: $PI_IP"
echo ""

# Prüfe SSH
echo "🔍 Prüfe SSH-Verbindung..."
if ! sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
    echo "❌ SSH-Verbindung fehlgeschlagen"
    echo "   Versuche Standard-Passwörter..."
    for pass in "moodeaudio" "raspberry" "moode"; do
        if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
            PI_PASS="$pass"
            echo "✅ SSH funktioniert mit Passwort: $pass"
            break
        fi
    done
    if [ "$PI_PASS" = "moodeaudio" ]; then
        echo "❌ SSH-Verbindung nicht möglich"
        exit 1
    fi
fi

echo "✅ SSH-Verbindung funktioniert"
echo ""

# WLAN-Daten
WIFI_SSID="TAVEE-II"
WIFI_PASSWORD="D76DE8F2CF"

echo "📶 Konfiguriere WLAN..."
echo "   SSID: $WIFI_SSID"
echo ""

# Erstelle wpa_supplicant.conf auf dem Pi
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << EOF
sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null << WPA_EOF
country=DE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
}
WPA_EOF

sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
sudo systemctl restart wpa_supplicant 2>/dev/null || sudo systemctl restart wpa_supplicant@wlan0 2>/dev/null || true
EOF

if [ $? -eq 0 ]; then
    echo "✅ WLAN konfiguriert"
    echo ""
    echo "🔄 WLAN-Service wird neu gestartet..."
    echo "   (Kann 30-60 Sekunden dauern)"
    echo ""
    echo "📋 Prüfe WLAN-Verbindung:"
    echo "   ssh $PI_USER@$PI_IP"
    echo "   sudo iwconfig wlan0"
    echo "   sudo ifconfig wlan0"
else
    echo "❌ WLAN-Konfiguration fehlgeschlagen"
    exit 1
fi

echo ""

