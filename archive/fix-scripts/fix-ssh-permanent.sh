#!/bin/bash
################################################################################
# PERMANENT SSH FIX
# 
# Ensures SSH is permanently enabled and survives reboots:
# 1. Enable SSH service (systemctl enable ssh)
# 2. Start SSH service (systemctl start ssh)
# 3. Create /boot/firmware/ssh flag file (for first boot)
# 4. Create systemd service to ensure SSH stays enabled
#
# Usage: ./fix-ssh-permanent.sh [PI_IP] [USER] [PASS]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Configuration
PI_IP="${1:-192.168.1.226}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 PERMANENT SSH FIX                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Pi: $PI_USER@$PI_IP"
echo ""

# Check sshpass
if ! command -v sshpass &> /dev/null; then
    error "sshpass nicht gefunden. Installiere mit: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

# Test SSH connection
info "Teste SSH-Verbindung..."
if ! sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
    error "SSH-Verbindung fehlgeschlagen. Prüfe IP, User und Passwort."
    exit 1
fi
log "✅ SSH-Verbindung erfolgreich"
echo ""

################################################################################
# FIX SSH PERMANENTLY
################################################################################

log "=== FIX SSH PERMANENTLY ==="
echo ""

info "Wende permanenten SSH-Fix an..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'SSH_FIX'
set -e

echo "1. Erstelle /boot/firmware/ssh Flag-Datei..."
sudo mount -o remount,rw /boot/firmware 2>/dev/null || true
sudo touch /boot/firmware/ssh
sudo chmod 644 /boot/firmware/ssh
echo "   ✅ /boot/firmware/ssh erstellt"

echo ""
echo "2. Aktiviere SSH Service..."
sudo systemctl enable ssh
sudo systemctl enable ssh.service
echo "   ✅ SSH Service aktiviert (systemctl enable)"

echo ""
echo "3. Starte SSH Service..."
sudo systemctl start ssh
sudo systemctl start ssh.service
echo "   ✅ SSH Service gestartet"

echo ""
echo "4. Erstelle systemd Service für permanente SSH-Aktivierung..."
sudo tee /etc/systemd/system/ensure-ssh-enabled.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Ensure SSH is permanently enabled
After=network.target
Before=ssh.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'systemctl enable ssh && systemctl start ssh && touch /boot/firmware/ssh'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF

sudo systemctl enable ensure-ssh-enabled.service
echo "   ✅ ensure-ssh-enabled.service erstellt und aktiviert"

echo ""
echo "5. Verifiziere SSH Status..."
SSH_ENABLED=$(systemctl is-enabled ssh 2>/dev/null || echo "unknown")
SSH_ACTIVE=$(systemctl is-active ssh 2>/dev/null || echo "unknown")
SSH_FLAG=$(test -f /boot/firmware/ssh && echo "exists" || echo "missing")

echo "   SSH Service enabled: $SSH_ENABLED"
echo "   SSH Service active: $SSH_ACTIVE"
echo "   /boot/firmware/ssh: $SSH_FLAG"

if [ "$SSH_ENABLED" = "enabled" ] && [ "$SSH_ACTIVE" = "active" ] && [ "$SSH_FLAG" = "exists" ]; then
    echo ""
    echo "✅ SSH ist permanent aktiviert!"
else
    echo ""
    echo "⚠️  SSH Status unvollständig, aber Fix wurde angewendet"
fi

sync
SSH_FIX

echo ""
log "=== SSH FIX ABGESCHLOSSEN ==="
echo ""
info "SSH sollte jetzt permanent aktiviert sein:"
echo "  ✅ systemctl enable ssh"
echo "  ✅ /boot/firmware/ssh Flag-Datei"
echo "  ✅ ensure-ssh-enabled.service (stellt SSH bei jedem Boot sicher)"
echo ""
log "Fix abgeschlossen!"

