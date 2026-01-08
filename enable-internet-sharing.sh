#!/bin/bash
################################################################################
# ENABLE INTERNET SHARING ON MAC
# 
# Enables Internet Sharing from Mac to Pi via Ethernet cable
# This allows the Pi to access the internet through the Mac
#
# Usage: ./enable-internet-sharing.sh
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🌐 ENABLE INTERNET SHARING MAC → PI                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# CHECK CURRENT STATUS
################################################################################

info "=== Prüfe Netzwerk-Status ==="
echo ""

# Find internet interface (usually Wi-Fi or Ethernet)
INTERNET_IF=$(route get default 2>/dev/null | grep interface | awk '{print $2}' || echo "")
if [ -n "$INTERNET_IF" ]; then
    log "Internet-Interface: $INTERNET_IF"
else
    warn "Kein Internet-Interface gefunden"
fi

# Find Ethernet interface
ETHERNET_IF=$(networksetup -listallhardwareports 2>/dev/null | grep -A 1 "Ethernet\|USB.*Ethernet" | grep "Device:" | awk '{print $2}' | head -1)
if [ -n "$ETHERNET_IF" ]; then
    log "Ethernet-Interface: $ETHERNET_IF"
else
    warn "Ethernet-Interface nicht gefunden"
fi

echo ""

################################################################################
# ENABLE INTERNET SHARING
################################################################################

info "=== Aktiviere Internet-Sharing ==="
echo ""

warn "⚠️  Internet-Sharing muss manuell aktiviert werden:"
echo ""
info "Option 1: Über Systemeinstellungen (empfohlen)"
echo "  1. Öffne: Systemeinstellungen → Freigabe → Internetfreigabe"
echo "  2. Aktiviere 'Internetfreigabe'"
echo "  3. Wähle deine Internet-Verbindung (z.B. Wi-Fi) als Quelle"
echo "  4. Wähle 'Ethernet' als geteiltes Interface"
echo "  5. Aktiviere die Checkbox"
echo ""

info "Option 2: Über Terminal (benötigt Admin-Rechte)"
echo "  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
echo "  sudo pfctl -d"
echo "  sudo pfctl -f /etc/pf.conf"
echo ""

info "Option 3: Manuell konfigurieren"
echo "  sudo sysctl -w net.inet.ip.forwarding=1"
echo "  sudo ifconfig $ETHERNET_IF 192.168.2.1 netmask 255.255.255.0"
echo ""

################################################################################
# CONFIGURE PI NETWORK
################################################################################

info "=== Pi Netzwerk konfigurieren ==="
echo ""

PI_IP="192.168.1.101"
info "Pi IP: $PI_IP"
echo ""

warn "Nach Aktivierung des Internet-Sharings:"
echo "  1. Pi sollte Internet haben"
echo "  2. Teste: ping 8.8.8.8 (auf dem Pi)"
echo "  3. Oder: curl -I http://google.com (auf dem Pi)"
echo ""

################################################################################
# QUICK TEST
################################################################################

info "=== Test Internet-Sharing ==="
echo ""

if [ -n "$PI_IP" ]; then
    info "Teste Pi-Verbindung..."
    if ping -c 1 -W 1 "$PI_IP" >/dev/null 2>&1; then
        log "✅ Pi erreichbar: $PI_IP"
        echo ""
        info "Um Internet auf dem Pi zu testen, führe im WebSSH aus:"
        echo "  ping -c 3 8.8.8.8"
        echo "  curl -I http://google.com"
    else
        warn "⚠️  Pi nicht erreichbar: $PI_IP"
    fi
fi

echo ""
log "=== Fertig ==="
echo ""
info "Nach Aktivierung des Internet-Sharings sollte der Pi Internet haben!"
echo ""

