#!/bin/bash
################################################################################
# APPLY CONFIG VIA WEBSSH
# 
# Dieses Skript kann über WebSSH ausgeführt werden, um:
# 1. SSH zu aktivieren
# 2. Config-Dateien anzuwenden
################################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 APPLY CONFIG VIA WEBSSH                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Enable SSH
info "Aktiviere SSH..."
sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null || true
sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null || true
sudo touch /boot/firmware/ssh 2>/dev/null || sudo touch /boot/ssh 2>/dev/null || true
log "✅ SSH aktiviert"

# 2. Check if config file exists
if [ -f "/tmp/config.txt" ]; then
    info "Wende config.txt an..."
    sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    sudo mount -o remount,rw /boot/firmware 2>/dev/null || true
    sudo cp /tmp/config.txt /boot/firmware/config.txt
    sudo chmod 644 /boot/firmware/config.txt
    log "✅ config.txt angewendet"
else
    warn "⚠️  /tmp/config.txt nicht gefunden"
    info "Bitte Config-Datei zuerst hochladen"
fi

# 3. Sync
sync
log "✅ Alle Änderungen gespeichert"

echo ""
log "✅ Setup abgeschlossen!"
echo ""
info "SSH ist jetzt aktiviert für nächsten Boot"
info "Reboot erforderlich, um Config anzuwenden"
echo ""

