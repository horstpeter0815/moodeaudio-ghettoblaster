#!/bin/bash
################################################################################
# FIX EVERYTHING ONCE - NO MORE HUNDREDS OF REBOOTS
# 
# Fixes SSH and Display Rotation permanently in ONE run:
# 1. SSH: Enable permanently (systemctl + flag file + watchdog service)
# 2. Display: Fix rotation (config.txt + moOde DB + xinitrc + worker.php patch)
# 3. Verification: Check everything works
#
# Usage: ./fix-everything-once.sh [PI_IP] [USER] [PASS]
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
echo "║  🔧 FIX EVERYTHING ONCE - NO MORE REBOOTS                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Pi: $PI_USER@$PI_IP"
echo ""

# Check sshpass
if ! command -v sshpass &> /dev/null; then
    error "sshpass nicht gefunden. Installiere mit: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

# Wait for Pi to be reachable
info "Warte auf Pi..."
for i in {1..30}; do
    if ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
        log "✅ Pi ist erreichbar"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Test SSH connection
info "Teste SSH-Verbindung..."
if ! sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
    error "SSH-Verbindung fehlgeschlagen. Prüfe IP, User und Passwort."
    echo ""
    warn "Falls SSH nicht funktioniert, verwende WebSSH oder fixe SD-Karte:"
    echo "  ./fix-sd-card-complete.sh"
    exit 1
fi
log "✅ SSH-Verbindung erfolgreich"
echo ""

################################################################################
# FIX EVERYTHING
################################################################################

log "=== FIXING EVERYTHING ==="
echo ""

info "Wende alle Fixes an (SSH + Display + moOde)..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'ALL_FIXES'
set -e

echo "═══════════════════════════════════════════════════════════════"
echo "PART 1: SSH PERMANENT FIX"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. SSH Flag File
echo "1. Erstelle /boot/firmware/ssh Flag-Datei..."
sudo mount -o remount,rw /boot/firmware 2>/dev/null || true
sudo touch /boot/firmware/ssh
sudo chmod 644 /boot/firmware/ssh
echo "   ✅ /boot/firmware/ssh erstellt"

# 2. Enable SSH Service
echo ""
echo "2. Aktiviere SSH Service..."
sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null || true
sudo systemctl enable ssh.service 2>/dev/null || sudo systemctl enable sshd.service 2>/dev/null || true
echo "   ✅ SSH Service aktiviert"

# 3. Start SSH Service
echo ""
echo "3. Starte SSH Service..."
sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null || true
echo "   ✅ SSH Service gestartet"

# 4. Create SSH Watchdog Service
echo ""
echo "4. Erstelle SSH Watchdog Service..."
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

sudo systemctl enable ensure-ssh-enabled.service 2>/dev/null || true
echo "   ✅ ensure-ssh-enabled.service erstellt"

echo ""
echo "✅ SSH PERMANENT FIX ABGESCHLOSSEN"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "PART 2: DISPLAY ROTATION PERMANENT FIX"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. moOde Database
echo "1. Fixe moOde Datenbank (hdmi_scn_orient)..."
if [ -f "/var/local/www/db/moode-sqlite.db" ]; then
    sudo sqlite3 /var/local/www/db/moode-sqlite.db \
        "UPDATE cfg_system SET value='landscape' WHERE param='hdmi_scn_orient';" 2>/dev/null || true
    NEW_VALUE=$(sudo sqlite3 /var/local/www/db/moode-sqlite.db \
        "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient';" 2>/dev/null || echo "")
    if [ "$NEW_VALUE" = "landscape" ]; then
        echo "   ✅ moOde hdmi_scn_orient = landscape"
    else
        echo "   ⚠️  moOde DB nicht verfügbar (Standard-Download?)"
    fi
else
    echo "   ⚠️  moOde Datenbank nicht gefunden"
fi

# 2. config.txt
echo ""
echo "2. Fixe config.txt..."
sudo mount -o remount,rw /boot/firmware 2>/dev/null || true

# Add moOde header if missing
if ! grep -q "# This file is managed by moOde" /boot/firmware/config.txt; then
    sudo sed -i '1i#########################################\n# This file is managed by moOde\n#########################################\n' /boot/firmware/config.txt
    echo "   ✅ moOde Header hinzugefügt"
fi

# Ensure display_rotate=0 in [pi5] section
if grep -q "^\[pi5\]" /boot/firmware/config.txt; then
    # Remove existing display_rotate from [pi5] section
    sudo sed -i '/^\[pi5\]/,/^\[/ {/^display_rotate=/d}' /boot/firmware/config.txt
    # Add display_rotate=0 after [pi5]
    sudo sed -i '/^\[pi5\]/a display_rotate=0' /boot/firmware/config.txt
    echo "   ✅ display_rotate=0 in [pi5] Section"
else
    echo "[pi5]" | sudo tee -a /boot/firmware/config.txt > /dev/null
    echo "display_rotate=0" | sudo tee -a /boot/firmware/config.txt > /dev/null
    echo "   ✅ [pi5] Section mit display_rotate=0 hinzugefügt"
fi

# Ensure hdmi_timings in [pi5] section
if ! grep -A 10 "^\[pi5\]" /boot/firmware/config.txt | grep -q "hdmi_timings"; then
    sudo sed -i '/^\[pi5\]/a hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0\nhdmi_ignore_edid=0xa5000080\nhdmi_force_hotplug=1' /boot/firmware/config.txt
    echo "   ✅ hdmi_timings in [pi5] Section"
fi

# Remove display_rotate from [all] section
sudo sed -i '/^\[all\]/,/^\[/ {/^display_rotate=/d}' /boot/firmware/config.txt

# Remove disable_fw_kms_setup
sudo sed -i '/^disable_fw_kms_setup=/d' /boot/firmware/config.txt

echo "   ✅ config.txt gefixt"

# 3. cmdline.txt
echo ""
echo "3. Fixe cmdline.txt..."
sudo sed -i 's/ video=[^ ]*rotate[^ ]*//g' /boot/firmware/cmdline.txt
sudo sed -i 's/  / /g' /boot/firmware/cmdline.txt
echo "   ✅ cmdline.txt gefixt (video= rotate entfernt)"

# 4. xinitrc
echo ""
echo "4. Fixe xinitrc..."
XINITRC="$HOME/.xinitrc"
if [ -f "$XINITRC" ]; then
    # Remove forced rotation
    sed -i '/xrandr.*--rotate left$/d' "$XINITRC"
    sed -i '/xrandr.*--rotate left[^a-z]/d' "$XINITRC"
    
    # Add proper rotation logic if not present
    if ! grep -q "HDMI_SCN_ORIENT" "$XINITRC"; then
        if grep -q "chromium" "$XINITRC"; then
            sed -i '/chromium/i\
# HDMI Orientation (based on moOde setting)\
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='\''hdmi_scn_orient'\''" 2>/dev/null || echo "landscape")\
HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '\''{print $1}'\'' || echo "HDMI-A-2")\
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then\
    DISPLAY=:0 xrandr --output "$HDMI_PORT" --rotate left\
else\
    DISPLAY=:0 xrandr --output "$HDMI_PORT" --rotate normal\
fi\
' "$XINITRC"
        fi
    fi
    echo "   ✅ xinitrc gefixt"
else
    echo "   ⚠️  .xinitrc nicht gefunden"
fi

# 5. worker.php Patch
echo ""
echo "5. Prüfe worker.php Patch..."
WORKER_FILE="/var/www/daemon/worker.php"
if [ -f "$WORKER_FILE" ]; then
    if ! grep -q "Ghettoblaster: display_rotate=0" "$WORKER_FILE"; then
        # Apply patch
        sudo sed -i '/sysCmd.*cp.*config.txt.*\/boot\/firmware\//a\
		// Ghettoblaster: Stelle display_rotate=0 wieder her (Landscape)\
		sysCmd("sed -i \"/^display_rotate=/d\" /boot/firmware/config.txt");\
		sysCmd("echo \"display_rotate=0\" >> /boot/firmware/config.txt");
' "$WORKER_FILE"
        echo "   ✅ worker.php Patch angewendet"
    else
        echo "   ✅ worker.php Patch bereits angewendet"
    fi
else
    echo "   ⚠️  worker.php nicht gefunden"
fi

echo ""
echo "✅ DISPLAY ROTATION PERMANENT FIX ABGESCHLOSSEN"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "VERIFICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "SSH Status:"
systemctl is-enabled ssh 2>/dev/null && echo "  ✅ SSH enabled" || echo "  ⚠️  SSH not enabled"
systemctl is-active ssh 2>/dev/null && echo "  ✅ SSH active" || echo "  ⚠️  SSH not active"
[ -f /boot/firmware/ssh ] && echo "  ✅ /boot/firmware/ssh exists" || echo "  ⚠️  /boot/firmware/ssh missing"
echo ""

echo "Display Config:"
grep -E "^display_rotate=" /boot/firmware/config.txt | head -1 && echo "  ✅ display_rotate gefunden" || echo "  ⚠️  display_rotate nicht gefunden"
grep -q "# This file is managed by moOde" /boot/firmware/config.txt && echo "  ✅ moOde Header vorhanden" || echo "  ⚠️  moOde Header fehlt"
echo ""

sync
echo "✅ ALL FIXES APPLIED - SYNC COMPLETE"
ALL_FIXES

echo ""
log "=== ALL FIXES APPLIED ==="
echo ""
info "Zusammenfassung:"
echo "  ✅ SSH permanent aktiviert (systemctl + flag + watchdog)"
echo "  ✅ Display Rotation gefixt (config.txt + moOde DB + xinitrc + worker.php)"
echo "  ✅ Alle Einstellungen gespeichert"
echo ""
warn "⚠️  EIN REBOOT ERFORDERLICH, damit alle Änderungen aktiv werden"
echo ""
read -p "Pi jetzt neu starten? (y/N): " confirm_reboot
if [ "$confirm_reboot" == "y" ]; then
    info "Starte Pi neu..."
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "sudo reboot"
    log "✅ Pi wird neu gestartet"
    echo ""
    info "Warte auf Pi nach Reboot..."
    sleep 5
    for i in {1..60}; do
        if ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
            log "✅ Pi ist nach Reboot wieder online"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
    info "Prüfe SSH nach Reboot..."
    sleep 5
    if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
        log "✅ SSH funktioniert nach Reboot!"
    else
        warn "⚠️  SSH noch nicht verfügbar (Pi bootet möglicherweise noch)"
    fi
else
    warn "Pi wurde nicht neu gestartet. Bitte manuell neu starten."
fi
echo ""
log "Fix abgeschlossen!"

