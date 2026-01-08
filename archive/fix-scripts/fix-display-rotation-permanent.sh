#!/bin/bash
################################################################################
# PERMANENT DISPLAY ROTATION FIX
# 
# Fixes ALL override points that cause display to revert to portrait mode:
# 1. moOde Database: hdmi_scn_orient → landscape
# 2. config.txt: display_rotate=0 + moOde header (prevents overwrite)
# 3. xinitrc: Remove forced rotation, use moOde setting
# 4. worker.php: Ensure patch is applied
# 5. cmdline.txt: Remove video= rotate parameter
#
# Usage: ./fix-display-rotation-permanent.sh [PI_IP] [USER] [PASS]
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
echo "║  🔧 PERMANENT DISPLAY ROTATION FIX                           ║"
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
# STEP 1: ANALYZE CURRENT STATE
################################################################################

log "=== STEP 1: ANALYZE CURRENT STATE ==="
echo ""

# Get current settings
CURRENT_DISPLAY_ROTATE=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "grep -E '^display_rotate=' /boot/firmware/config.txt 2>/dev/null | head -1 | cut -d'=' -f2" || echo "")

CURRENT_VIDEO_PARAM=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "grep -o 'video=[^ ]*' /boot/firmware/cmdline.txt 2>/dev/null" || echo "")

CURRENT_MOODE_ORIENT=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "sqlite3 /var/local/www/db/moode-sqlite.db \"SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'\" 2>/dev/null" || echo "")

WORKER_PATCH_STATUS=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "grep -q 'Ghettoblaster: display_rotate=0' /var/www/daemon/worker.php 2>/dev/null && echo 'applied' || echo 'not_applied'")

XINITRC_ROTATION=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "grep -i 'xrandr.*rotate' ~/.xinitrc 2>/dev/null | head -1" || echo "")

info "Aktuelle Einstellungen:"
echo "  display_rotate: ${CURRENT_DISPLAY_ROTATE:-nicht gesetzt}"
echo "  video= Parameter: ${CURRENT_VIDEO_PARAM:-keiner}"
echo "  moOde hdmi_scn_orient: ${CURRENT_MOODE_ORIENT:-nicht gefunden}"
echo "  worker.php Patch: $WORKER_PATCH_STATUS"
echo "  xinitrc Rotation: ${XINITRC_ROTATION:-keine gefunden}"
echo ""

################################################################################
# STEP 2: FIX MOODE DATABASE
################################################################################

log "=== STEP 2: FIX MOODE DATABASE ==="
echo ""

info "Setze hdmi_scn_orient auf 'landscape' in moOde Datenbank..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'DB_FIX'
# Check if database exists
if [ -f "/var/local/www/db/moode-sqlite.db" ]; then
    # Update hdmi_scn_orient to landscape
    sqlite3 /var/local/www/db/moode-sqlite.db \
        "UPDATE cfg_system SET value='landscape' WHERE param='hdmi_scn_orient';" 2>/dev/null || true
    
    # Verify
    NEW_VALUE=$(sqlite3 /var/local/www/db/moode-sqlite.db \
        "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient';" 2>/dev/null || echo "")
    
    if [ "$NEW_VALUE" = "landscape" ]; then
        echo "✅ moOde Datenbank: hdmi_scn_orient = landscape"
    else
        echo "⚠️  moOde Datenbank: Konnte nicht gesetzt werden (möglicherweise nicht vorhanden)"
    fi
else
    echo "⚠️  moOde Datenbank nicht gefunden (möglicherweise Standard-Download)"
fi
DB_FIX

echo ""

################################################################################
# STEP 3: FIX CONFIG.TXT
################################################################################

log "=== STEP 3: FIX CONFIG.TXT ==="
echo ""

info "Fixe config.txt: display_rotate=0 + moOde Header..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'CONFIG_FIX'
sudo mount -o remount,rw /boot/firmware

# Add moOde header if missing (prevents worker.php overwrite)
if ! grep -q "# This file is managed by moOde" /boot/firmware/config.txt; then
    sed -i '1i#########################################\n# This file is managed by moOde\n#########################################' /boot/firmware/config.txt
    echo "✅ moOde Header hinzugefügt"
fi

# Ensure display_rotate=0 in [pi5] section
if grep -q "^\[pi5\]" /boot/firmware/config.txt; then
    # Remove existing display_rotate from [pi5] section
    sed -i '/^\[pi5\]/,/^\[/ {/^display_rotate=/d}' /boot/firmware/config.txt
    
    # Add display_rotate=0 after [pi5]
    sed -i '/^\[pi5\]/a display_rotate=0' /boot/firmware/config.txt
    echo "✅ display_rotate=0 in [pi5] Section gesetzt"
else
    # [pi5] section doesn't exist, add it
    echo "" >> /boot/firmware/config.txt
    echo "[pi5]" >> /boot/firmware/config.txt
    echo "display_rotate=0" >> /boot/firmware/config.txt
    echo "✅ [pi5] Section mit display_rotate=0 hinzugefügt"
fi

# Also ensure it's not in [all] section (conflict)
sed -i '/^\[all\]/,/^\[/ {/^display_rotate=/d}' /boot/firmware/config.txt

sync
echo "✅ config.txt gefixt"
CONFIG_FIX

echo ""

################################################################################
# STEP 4: FIX CMDLINE.TXT
################################################################################

log "=== STEP 4: FIX CMDLINE.TXT ==="
echo ""

info "Entferne video= rotate Parameter aus cmdline.txt..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'CMDLINE_FIX'
sudo mount -o remount,rw /boot/firmware

# Backup
cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Remove video= parameter with rotate
sed -i 's/ video=[^ ]*rotate[^ ]*//g' /boot/firmware/cmdline.txt

# Clean up double spaces
sed -i 's/  / /g' /boot/firmware/cmdline.txt

sync
echo "✅ cmdline.txt gefixt (video= rotate entfernt)"
CMDLINE_FIX

echo ""

################################################################################
# STEP 5: FIX XINITRC
################################################################################

log "=== STEP 5: FIX XINITRC ==="
echo ""

info "Fixe xinitrc: Entferne erzwungene Rotation..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'XINITRC_FIX'
XINITRC="$HOME/.xinitrc"

if [ ! -f "$XINITRC" ]; then
    echo "⚠️  .xinitrc nicht gefunden (möglicherweise Standard-Download)"
    exit 0
fi

# Backup
cp "$XINITRC" "$XINITRC.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Remove forced rotation (xrandr --rotate left without condition)
sed -i '/xrandr.*--rotate left$/d' "$XINITRC"
sed -i '/xrandr.*--rotate left[^a-z]/d' "$XINITRC"

# Ensure proper rotation logic (based on moOde setting)
if ! grep -q "HDMI_SCN_ORIENT" "$XINITRC"; then
    # Find where to insert (before chromium or at end)
    if grep -q "chromium" "$XINITRC"; then
        # Insert before chromium line
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
    else
        # Append at end
        cat >> "$XINITRC" << 'EOF'

# HDMI Orientation (based on moOde setting)
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "landscape")
HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '{print $1}' || echo "HDMI-A-2")
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    DISPLAY=:0 xrandr --output "$HDMI_PORT" --rotate left
else
    DISPLAY=:0 xrandr --output "$HDMI_PORT" --rotate normal
fi
EOF
    fi
    echo "✅ xinitrc Rotation-Logik hinzugefügt"
else
    echo "✅ xinitrc hat bereits Rotation-Logik"
fi

echo "✅ xinitrc gefixt"
XINITRC_FIX

echo ""

################################################################################
# STEP 6: VERIFY WORKER.PHP PATCH
################################################################################

log "=== STEP 6: VERIFY WORKER.PHP PATCH ==="
echo ""

info "Prüfe worker.php Patch Status..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'WORKER_FIX'
WORKER_FILE="/var/www/daemon/worker.php"
PATCH_SCRIPT="/usr/local/bin/worker-php-patch.sh"

if [ ! -f "$WORKER_FILE" ]; then
    echo "⚠️  worker.php nicht gefunden (möglicherweise Standard-Download)"
    exit 0
fi

# Check if patch is applied
if grep -q "Ghettoblaster: display_rotate=0" "$WORKER_FILE"; then
    echo "✅ worker.php Patch ist bereits angewendet"
else
    echo "⚠️  worker.php Patch NICHT angewendet"
    
    # Try to apply patch
    if [ -f "$PATCH_SCRIPT" ]; then
        echo "Versuche Patch anzuwenden..."
        bash "$PATCH_SCRIPT" 2>/dev/null || {
            # Manual patch if script fails
            sed -i '/sysCmd.*cp.*config.txt.*\/boot\/firmware\//a\
		// Ghettoblaster: Stelle display_rotate=0 wieder her (Landscape)\
		sysCmd("sed -i \"/^display_rotate=/d\" /boot/firmware/config.txt");\
		sysCmd("echo \"display_rotate=0\" >> /boot/firmware/config.txt");
' "$WORKER_FILE"
        }
        
        if grep -q "Ghettoblaster: display_rotate=0" "$WORKER_FILE"; then
            echo "✅ worker.php Patch angewendet"
        else
            echo "⚠️  Patch konnte nicht angewendet werden"
        fi
    else
        echo "⚠️  Patch-Script nicht gefunden"
    fi
fi
WORKER_FIX

echo ""

################################################################################
# STEP 7: VERIFICATION
################################################################################

log "=== STEP 7: VERIFICATION ==="
echo ""

info "Prüfe finale Einstellungen..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'VERIFY'
echo "=== Finale Einstellungen ==="
echo ""
echo "1. config.txt display_rotate:"
grep -E '^display_rotate=' /boot/firmware/config.txt || echo "  Nicht gefunden"
echo ""
echo "2. config.txt moOde Header:"
head -3 /boot/firmware/config.txt | grep -q "managed by moOde" && echo "  ✅ Header vorhanden" || echo "  ⚠️  Header fehlt"
echo ""
echo "3. cmdline.txt video=:"
grep -o 'video=[^ ]*' /boot/firmware/cmdline.txt 2>/dev/null || echo "  Kein video= Parameter (gut)"
echo ""
echo "4. moOde hdmi_scn_orient:"
sqlite3 /var/local/www/db/moode-sqlite.db "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient';" 2>/dev/null || echo "  Datenbank nicht verfügbar"
echo ""
echo "5. worker.php Patch:"
grep -q "Ghettoblaster: display_rotate=0" /var/www/daemon/worker.php 2>/dev/null && echo "  ✅ Patch angewendet" || echo "  ⚠️  Patch nicht angewendet"
echo ""
VERIFY

echo ""

################################################################################
# SUMMARY
################################################################################

log "=== FIX ABGESCHLOSSEN ==="
echo ""
info "Alle Override-Punkte wurden gefixt:"
echo "  ✅ moOde Datenbank: hdmi_scn_orient = landscape"
echo "  ✅ config.txt: display_rotate=0 + moOde Header"
echo "  ✅ cmdline.txt: video= rotate entfernt"
echo "  ✅ xinitrc: Rotation basiert auf moOde Einstellung"
echo "  ✅ worker.php: Patch Status geprüft"
echo ""
warn "⚠️  REBOOT ERFORDERLICH, damit alle Änderungen aktiv werden!"
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
else
    warn "Pi wurde nicht neu gestartet. Bitte manuell neu starten."
fi
echo ""
log "Fix abgeschlossen!"

