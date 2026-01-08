#!/bin/bash
################################################################################
# SIMPLE SSH FIX - REALISTIC APPROACH
# 
# Based on what actually works:
# 1. Create /boot/firmware/ssh flag (standard Raspberry Pi method)
# 2. One simple systemd service that enables SSH early
# 3. WebSSH as backup option (already works in moOde)
#
# No "100% guarantee" promises - just what should work.
#
# Usage: ./simple-ssh-fix.sh [SD_MOUNT_POINT]
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

SD_MOUNT="${1:-}"

# Find SD card
if [ -z "$SD_MOUNT" ]; then
    if [ -d "/Volumes/bootfs" ]; then
        SD_MOUNT="/Volumes/bootfs"
    elif [ -d "/Volumes/boot" ]; then
        SD_MOUNT="/Volumes/boot"
    else
        error "SD-Karte nicht gefunden"
        echo ""
        info "Optionen:"
        info "  1. SD-Karte einstecken und Script erneut ausführen"
        info "  2. WebSSH verwenden: http://<PI_IP>:4200 (funktioniert bereits)"
        exit 1
    fi
fi

CONFIG_FILE="$SD_MOUNT/config.txt"
SSH_FLAG="$SD_MOUNT/ssh"

if [ ! -d "$SD_MOUNT" ]; then
    error "SD-Karte nicht gefunden: $SD_MOUNT"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 SIMPLE SSH FIX - REALISTIC APPROACH                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "SD-Karte: $SD_MOUNT"
echo ""

################################################################################
# STEP 1: CREATE SSH FLAG FILE
################################################################################

log "=== STEP 1: CREATE SSH FLAG FILE ==="
echo ""

# Create SSH flag (standard Raspberry Pi method)
touch "$SSH_FLAG"
log "✅ Created: $SSH_FLAG"

# Also try firmware directory (Pi 5)
if [ -d "$SD_MOUNT/firmware" ]; then
    touch "$SD_MOUNT/firmware/ssh"
    log "✅ Created: $SD_MOUNT/firmware/ssh"
fi

echo ""

################################################################################
# STEP 2: CHECK IF ROOTFS IS AVAILABLE
################################################################################

ROOTFS_MOUNT=""
if [ -d "$SD_MOUNT/../rootfs" ]; then
    ROOTFS_MOUNT="$SD_MOUNT/../rootfs"
elif mount | grep -q "rootfs\|ext4.*on.*rootfs"; then
    ROOTFS_MOUNT=$(mount | grep "rootfs\|ext4" | awk '{print $3}' | head -1)
fi

if [ -z "$ROOTFS_MOUNT" ]; then
    warn "⚠️  Root-Filesystem nicht gemountet"
    warn "   Nur SSH-Flag erstellt (sollte funktionieren)"
    echo ""
    info "Nächste Schritte:"
    info "  1. SD-Karte auswerfen"
    info "  2. SD-Karte in Pi einstecken"
    info "  3. Pi booten"
    info "  4. SSH sollte funktionieren: ssh andre@<PI_IP> (Pass: 0815)"
    echo ""
    info "Falls SSH nicht funktioniert:"
    info "  → WebSSH verwenden: http://<PI_IP>:4200"
    exit 0
fi

log "✅ Root-Filesystem gefunden: $ROOTFS_MOUNT"
echo ""

################################################################################
# STEP 3: INSTALL SIMPLE SYSTEMD SERVICE
################################################################################

log "=== STEP 2: INSTALL SIMPLE SYSTEMD SERVICE ==="
echo ""

SYSTEMD_DIR="$ROOTFS_MOUNT/etc/systemd/system"
mkdir -p "$SYSTEMD_DIR"

# Create ONE simple service (not 27 layers!)
cat > "$SYSTEMD_DIR/enable-ssh-early.service" << 'SERVICE_EOF'
[Unit]
Description=Enable SSH Early
After=local-fs.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true; systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true; systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF

log "✅ Created: enable-ssh-early.service"

# Enable service
WANTS_DIR="$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANTS_DIR"
ln -sf "$SYSTEMD_DIR/enable-ssh-early.service" "$WANTS_DIR/enable-ssh-early.service" 2>/dev/null || true
log "✅ Enabled: enable-ssh-early.service"

echo ""

################################################################################
# SUMMARY
################################################################################

log "=== FIX ABGESCHLOSSEN ==="
echo ""
info "Was wurde gemacht:"
echo "  ✅ SSH-Flag-Datei erstellt: $SSH_FLAG"
echo "  ✅ Systemd-Service installiert: enable-ssh-early.service"
echo ""
warn "⚠️  SD-Karte kann jetzt ausgeworfen werden"
echo ""
info "Nächste Schritte:"
info "  1. SD-Karte auswerfen"
info "  2. SD-Karte in Pi einstecken"
info "  3. Pi booten"
info "  4. SSH testen: ssh andre@<PI_IP> (Pass: 0815)"
echo ""
info "Falls SSH nicht funktioniert:"
info "  → WebSSH verwenden: http://<PI_IP>:4200"
info "  → Im WebSSH: sudo systemctl enable ssh && sudo systemctl start ssh"
echo ""

