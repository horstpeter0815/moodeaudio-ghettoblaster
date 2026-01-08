#!/bin/bash
################################################################################
# FIX SSH AND DISPLAY VIA WEBSSH
# 
# Since SSH doesn't work after reboot, this uses WebSSH (port 4200) to:
# 1. Enable SSH permanently
# 2. Fix display rotation (180°)
# 3. Ensure all settings persist after reboot
#
# Usage: ./fix-ssh-display-via-webssh.sh [PI_IP]
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

PI_IP="${1:-}"

# Find Pi IP
if [ -z "$PI_IP" ]; then
    info "Suche Pi..."
    for ip in "moodepi5.local" "192.168.1.100" "192.168.1.101" "192.168.178.162"; do
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            RESOLVED=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
            PI_IP="${RESOLVED:-$ip}"
            break
        fi
    done
fi

if [ -z "$PI_IP" ]; then
    error "Pi IP nicht gefunden. Bitte angeben: $0 [PI_IP]"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX SSH AND DISPLAY VIA WEBSSH                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Pi: $PI_IP"
echo ""

# Check WebSSH
info "Prüfe WebSSH..."
if ! curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://$PI_IP:4200 | grep -qE "200|000"; then
    error "WebSSH nicht verfügbar auf http://$PI_IP:4200"
    exit 1
fi
log "✅ WebSSH verfügbar"
echo ""

# Create script that will be executed via WebSSH
cat > /tmp/fix-commands.sh << 'FIX_EOF'
#!/bin/bash
# Commands to fix SSH and Display

echo "=== FIX SSH ==="
sudo systemctl enable ssh
sudo systemctl start ssh
sudo touch /boot/firmware/ssh
sudo chmod 644 /boot/firmware/ssh
echo "✅ SSH enabled"

echo ""
echo "=== FIX DISPLAY ==="
sudo mount -o remount,rw /boot/firmware

# Ensure all Moode headers
CONFIG_FILE="/boot/firmware/config.txt"
if ! grep -q "^# This file is managed by moOde" "$CONFIG_FILE"; then
    sed -i '1i# This file is managed by moOde' "$CONFIG_FILE"
fi

# Fix display_rotate=2 in [pi5] section
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    # Remove existing display_rotate
    sed -i '/^\[pi5\]/,/^\[/ {/^display_rotate=/d}' "$CONFIG_FILE"
    # Add display_rotate=2
    sed -i '/^\[pi5\]/a display_rotate=2' "$CONFIG_FILE"
else
    # Add [pi5] section
    sed -i '/^# Device filters$/a\
[pi5]\
display_rotate=2
' "$CONFIG_FILE"
fi

# Fix cmdline.txt
CMDLINE_FILE="/boot/firmware/cmdline.txt"
sed -i 's/ fbcon=rotate:[0-9]//g' "$CMDLINE_FILE"
sed -i 's/$/ fbcon=rotate:3/' "$CMDLINE_FILE"

sync
echo "✅ Display fixed"

echo ""
echo "=== DONE ==="
FIX_EOF

chmod +x /tmp/fix-commands.sh

info "Bitte führe diese Befehle im WebSSH aus:"
echo ""
echo "1. Öffne WebSSH: http://$PI_IP:4200"
echo ""
echo "2. Kopiere und führe diese Befehle aus:"
echo ""
cat /tmp/fix-commands.sh
echo ""
echo ""
warn "⚠️  Nach dem Ausführen:"
warn "  1. SSH sollte funktionieren: ssh andre@$PI_IP"
warn "  2. Reboot: sudo reboot"
warn "  3. Nach Reboot sollte Display korrekt sein"

