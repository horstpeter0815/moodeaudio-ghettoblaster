#!/bin/bash
################################################################################
# CHECK PI STATUS AFTER BOOT
#
# Prüft nach dem Boot:
# 1. Ist Pi online?
# 2. Funktioniert SSH?
# 3. Ist config.txt noch korrekt? (wurde NICHT überschrieben)
# 4. Funktioniert Display-Rotation?
# 5. Ist worker.php gefixt?
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[CHECK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 PI STATUS CHECK NACH BOOT                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PI_USER="andre"
PI_PASS="0815"

# Find Pi IP
# ⚠️ WICHTIG: 192.168.1.101 ist der FREMDE WLAN-ROUTER, NICHT der Pi!
PI_IP=""
for ip in "192.168.10.2" "192.168.1.100" "moodepi5.local" "GhettoBlaster.local"; do
    # ⚠️ KRITISCH: .101 ist der fremde Router, NICHT der Pi!
    if echo "$ip" | grep -q "\.101$"; then
        warn "⚠️  Überspringe $ip (fremder WLAN-Router, NICHT der Pi!)"
        continue
    fi
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        PI_IP="$ip"
        break
    fi
done

if [ -z "$PI_IP" ]; then
    error "Pi nicht gefunden"
    echo ""
    info "Versuche IPs:"
    echo "  - 192.168.1.100 (LAN)"
    echo "  - 192.168.1.101 (WLAN)"
    echo "  - 192.168.10.2 (Direct LAN)"
    echo "  - moodepi5.local"
    echo "  - GhettoBlaster.local"
    echo ""
    warn "Bitte prüfe:"
    echo "  1. Ist Pi gebootet?"
    echo "  2. Ist Netzwerk-Kabel angeschlossen?"
    echo "  3. Ist WLAN konfiguriert?"
    exit 1
fi

log "✅ Pi gefunden: $PI_IP"
echo ""

# Check SSH
info "Prüfe SSH-Verbindung..."
if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
    log "✅ SSH funktioniert"
    SSH_OK=true
else
    error "❌ SSH funktioniert nicht"
    SSH_OK=false
    echo ""
    warn "Bitte manuell prüfen:"
    echo "  ssh $PI_USER@$PI_IP"
    exit 1
fi
echo ""

# Check config.txt
info "Prüfe config.txt (wurde NICHT überschrieben?)..."
CONFIG_CHECK=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'EOF'
CONFIG="/boot/firmware/config.txt"
echo "Zeile 1: '$(head -1 "$CONFIG")'"
echo "Zeile 2: '$(sed -n '2p' "$CONFIG")'"
echo ""
if sed -n '2p' "$CONFIG" | grep -q "This file is managed by moOde"; then
    echo "✅ Main Header in Zeile 2"
else
    echo "❌ Main Header NICHT in Zeile 2"
fi
echo ""
if grep -q "display_rotate=2" "$CONFIG"; then
    echo "✅ display_rotate=2 vorhanden"
else
    echo "❌ display_rotate=2 FEHLT"
fi
EOF
)

echo "$CONFIG_CHECK"
echo ""

# Check worker.php
info "Prüfe worker.php (ist Fix aktiv?)..."
WORKER_CHECK=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'EOF'
WORKER="/var/www/daemon/worker.php"
if grep -q "PERMANENT FIX" "$WORKER"; then
    echo "✅ worker.php hat PERMANENT FIX"
    grep "PERMANENT FIX" "$WORKER" | head -2
else
    echo "❌ worker.php hat KEINEN PERMANENT FIX"
    echo "   → config.txt könnte überschrieben werden!"
fi
EOF
)

echo "$WORKER_CHECK"
echo ""

# Final Summary
log "=== ZUSAMMENFASSUNG ==="
echo ""

if echo "$CONFIG_CHECK" | grep -q "✅ Main Header in Zeile 2" && echo "$CONFIG_CHECK" | grep -q "✅ display_rotate=2" && echo "$WORKER_CHECK" | grep -q "✅ worker.php hat PERMANENT FIX"; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ ALLES FUNKTIONIERT!                                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    log "✅ config.txt wurde NICHT überschrieben"
    log "✅ display_rotate=2 vorhanden"
    log "✅ worker.php hat Fixes"
    log "✅ SSH funktioniert"
    echo ""
    info "Der Pi ist bereit!"
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ⚠️  EINIGE PROBLEME GEFUNDEN                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    warn "Bitte prüfe die Fehlermeldungen oben"
fi

echo ""

