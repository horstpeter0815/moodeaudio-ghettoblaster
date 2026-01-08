#!/bin/bash
################################################################################
#
# CONFIGURE WLAN ONLY - NUR WLAN, SONST NICHTS
#
# Konfiguriert NUR WLAN auf der SD-Karte, wie es nach dem Brennen existiert.
# Keine anderen Änderungen!
#
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[WLAN]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📶 CONFIGURE WLAN ONLY - NUR WLAN, SONST NICHTS            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
else
    error "SD-Karte nicht gefunden"
    echo ""
    echo "Bitte SD-Karte in den Mac einstecken und warten, bis sie gemountet ist."
    exit 1
fi

log "SD-Karte gefunden: $SD_MOUNT"
echo ""

# WLAN-Daten
WIFI_SSID="TAVEE-II"
WIFI_PASSWORD="D76DE8F2CF"

log "WLAN-Daten:"
echo "  SSID: $WIFI_SSID"
echo "  Password: $WIFI_PASSWORD"
echo ""

# Erstelle wpa_supplicant.conf
log "Erstelle wpa_supplicant.conf..."

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

if sudo test -f "$SD_MOUNT/wpa_supplicant.conf"; then
    log "✅ wpa_supplicant.conf erstellt"
else
    error "❌ wpa_supplicant.conf konnte nicht erstellt werden"
    exit 1
fi

# Sync
sync

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ WLAN KONFIGURIERT                                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "Nur WLAN wurde konfiguriert. Alles andere bleibt unverändert."
echo ""
echo "Nächste Schritte:"
echo "  1. SD-Karte sicher auswerfen"
echo "  2. SD-Karte in Raspberry Pi 5 einstecken"
echo "  3. Pi booten"
echo "  4. WLAN sollte automatisch verbinden"
echo ""

