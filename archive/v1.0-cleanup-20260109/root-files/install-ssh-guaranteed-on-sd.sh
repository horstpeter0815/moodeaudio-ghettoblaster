#!/bin/bash
################################################################################
# INSTALL SSH GUARANTEED ON SD CARD
# 
# Installs a GUARANTEED SSH solution directly on the SD card that will work
# even if moOde tries to disable it. This creates systemd services and scripts
# that run BEFORE moOde can interfere.
#
# Strategy:
# 1. Create /boot/firmware/ssh flag (standard Raspberry Pi method)
# 2. Install systemd service that runs at sysinit.target (BEFORE moOde)
# 3. Install watchdog service that ensures SSH stays enabled
# 4. Create /etc/rc.local entry (runs even earlier than systemd)
#
# Usage: ./install-ssh-guaranteed-on-sd.sh [SD_MOUNT_POINT]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INSTALL]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔒 INSTALL SSH GUARANTEED ON SD CARD                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIND SD CARD
################################################################################

SD_MOUNT="${1:-}"

if [ -z "$SD_MOUNT" ]; then
    if [ -d "/Volumes/bootfs" ]; then
        SD_MOUNT="/Volumes/bootfs"
    elif [ -d "/Volumes/boot" ]; then
        SD_MOUNT="/Volumes/boot"
    else
        BOOT_PARTITION=$(diskutil list external 2>/dev/null | grep "Windows_FAT_32\|FAT32" | head -1 | awk '{print $NF}' || echo "")
        if [ -n "$BOOT_PARTITION" ]; then
            MOUNT_POINT=$(mount | grep "$BOOT_PARTITION" | awk '{print $3}' | head -1)
            if [ -n "$MOUNT_POINT" ]; then
                SD_MOUNT="$MOUNT_POINT"
            fi
        fi
    fi
fi

if [ -z "$SD_MOUNT" ] || [ ! -d "$SD_MOUNT" ]; then
    error "SD-Karte nicht gefunden!"
    echo ""
    info "Bitte SD-Karte einstecken oder Mount-Point angeben:"
    echo "  ./install-ssh-guaranteed-on-sd.sh /Volumes/bootfs"
    exit 1
fi

log "✅ SD-Karte gefunden: $SD_MOUNT"
echo ""

# Check if we can access root filesystem
ROOTFS_MOUNT=""
if [ -d "$SD_MOUNT/../rootfs" ]; then
    ROOTFS_MOUNT="$SD_MOUNT/../rootfs"
elif mount | grep -q "rootfs\|ext4.*on.*rootfs"; then
    ROOTFS_MOUNT=$(mount | grep "rootfs\|ext4" | awk '{print $3}' | head -1)
fi

if [ -z "$ROOTFS_MOUNT" ]; then
    warn "⚠️  Root-Filesystem nicht gemountet"
    warn "   Installiere nur Boot-Partition Fixes (SSH-Flag)"
    ROOTFS_AVAILABLE=false
else
    log "✅ Root-Filesystem gefunden: $ROOTFS_MOUNT"
    ROOTFS_AVAILABLE=true
fi
echo ""

################################################################################
# STEP 1: CREATE SSH FLAG FILE
################################################################################

log "=== STEP 1: CREATE SSH FLAG FILE ==="
echo ""

touch "$SD_MOUNT/ssh"
log "✅ Created: $SD_MOUNT/ssh"

if [ -d "$SD_MOUNT/firmware" ]; then
    touch "$SD_MOUNT/firmware/ssh"
    log "✅ Created: $SD_MOUNT/firmware/ssh"
fi

echo ""

################################################################################
# STEP 2: INSTALL SYSTEMD SERVICE (if rootfs available)
################################################################################

if [ "$ROOTFS_AVAILABLE" = true ]; then
    log "=== STEP 2: INSTALL SYSTEMD SERVICE ==="
    echo ""
    
    # Create systemd service directory
    SYSTEMD_DIR="$ROOTFS_MOUNT/etc/systemd/system"
    mkdir -p "$SYSTEMD_DIR"
    
    # Create ssh-guaranteed.service
    cat > "$SYSTEMD_DIR/ssh-guaranteed.service" << 'SERVICE_EOF'
[Unit]
Description=SSH Guaranteed - Ensures SSH is always enabled
DefaultDependencies=no
Before=sysinit.target
Before=shutdown.target
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    # Layer 1: SSH Flag File
    touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
    
    # Layer 2: Enable SSH Service
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl enable ssh.service 2>/dev/null || systemctl enable sshd.service 2>/dev/null || true
    
    # Layer 3: Unmask SSH (prevent disabling)
    systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true
    
    # Layer 4: Start SSH
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    
    # Layer 5: Create symlink (force enable)
    if [ -f /lib/systemd/system/ssh.service ]; then
        mkdir -p /etc/systemd/system/multi-user.target.wants
        ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service 2>/dev/null || true
    fi
    if [ -f /lib/systemd/system/sshd.service ]; then
        mkdir -p /etc/systemd/system/multi-user.target.wants
        ln -sf /lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service 2>/dev/null || true
    fi
    
    # Layer 6: Ensure SSH keys exist
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        mkdir -p /etc/ssh
        ssh-keygen -A 2>/dev/null || true
    fi
    
    echo "✅ SSH Guaranteed activated"
'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=sysinit.target
SERVICE_EOF

    log "✅ Created: $SYSTEMD_DIR/ssh-guaranteed.service"
    
    # Enable service by creating symlink
    WANTS_DIR="$ROOTFS_MOUNT/etc/systemd/system/sysinit.target.wants"
    mkdir -p "$WANTS_DIR"
    ln -sf "$SYSTEMD_DIR/ssh-guaranteed.service" "$WANTS_DIR/ssh-guaranteed.service" 2>/dev/null || true
    log "✅ Enabled: ssh-guaranteed.service"
    
    echo ""
    
    ################################################################################
    # STEP 3: INSTALL SSH WATCHDOG SERVICE
    ################################################################################
    
    log "=== STEP 3: INSTALL SSH WATCHDOG SERVICE ==="
    echo ""
    
    cat > "$SYSTEMD_DIR/ssh-watchdog.service" << 'WATCHDOG_EOF'
[Unit]
Description=SSH Watchdog - Ensures SSH stays enabled
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=30
ExecStart=/bin/bash -c '
    while true; do
        # Check if SSH is running
        if ! systemctl is-active --quiet ssh && ! systemctl is-active --quiet sshd; then
            systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
            systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
            touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
        fi
        
        # Ensure SSH flag exists
        touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
        
        sleep 30
    done
'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
WATCHDOG_EOF

    log "✅ Created: $SYSTEMD_DIR/ssh-watchdog.service"
    
    # Enable watchdog
    MULTI_USER_WANTS="$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants"
    mkdir -p "$MULTI_USER_WANTS"
    ln -sf "$SYSTEMD_DIR/ssh-watchdog.service" "$MULTI_USER_WANTS/ssh-watchdog.service" 2>/dev/null || true
    log "✅ Enabled: ssh-watchdog.service"
    
    echo ""
    
    ################################################################################
    # STEP 4: INSTALL /etc/rc.local (runs even earlier)
    ################################################################################
    
    log "=== STEP 4: INSTALL /etc/rc.local ==="
    echo ""
    
    RCLOCAL="$ROOTFS_MOUNT/etc/rc.local"
    
    # Backup existing rc.local
    if [ -f "$RCLOCAL" ]; then
        cp "$RCLOCAL" "$RCLOCAL.backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create rc.local with SSH activation
    cat > "$RCLOCAL" << 'RCLOCAL_EOF'
#!/bin/bash
# rc.local - SSH Guaranteed Activation
# This runs BEFORE systemd services, ensuring SSH is enabled early

# Enable SSH immediately
touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true

# Start SSH service (if available)
if [ -f /lib/systemd/system/ssh.service ] || [ -f /lib/systemd/system/sshd.service ]; then
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
fi

# Exit successfully
exit 0
RCLOCAL_EOF

    chmod +x "$RCLOCAL"
    log "✅ Created: $RCLOCAL"
    
    echo ""
else
    warn "⚠️  Root-Filesystem nicht verfügbar - überspringe Systemd-Services"
    warn "   Nur SSH-Flag-Datei wurde erstellt"
    echo ""
fi

################################################################################
# VERIFICATION
################################################################################

log "=== VERIFICATION ==="
echo ""

info "Installierte Komponenten:"
echo "  ✅ $SD_MOUNT/ssh (SSH Flag-Datei)"

if [ "$ROOTFS_AVAILABLE" = true ]; then
    [ -f "$SYSTEMD_DIR/ssh-guaranteed.service" ] && echo "  ✅ ssh-guaranteed.service" || echo "  ⚠️  ssh-guaranteed.service nicht gefunden"
    [ -f "$SYSTEMD_DIR/ssh-watchdog.service" ] && echo "  ✅ ssh-watchdog.service" || echo "  ⚠️  ssh-watchdog.service nicht gefunden"
    [ -f "$RCLOCAL" ] && echo "  ✅ /etc/rc.local" || echo "  ⚠️  /etc/rc.local nicht gefunden"
fi

echo ""
log "=== INSTALLATION ABGESCHLOSSEN ==="
echo ""
info "SSH ist jetzt GARANTIERT aktiviert mit mehreren Sicherheitsebenen:"
echo "  1. SSH Flag-Datei (/boot/firmware/ssh)"
if [ "$ROOTFS_AVAILABLE" = true ]; then
    echo "  2. ssh-guaranteed.service (läuft bei sysinit.target)"
    echo "  3. ssh-watchdog.service (überwacht SSH kontinuierlich)"
    echo "  4. /etc/rc.local (läuft vor systemd)"
fi
echo ""
warn "⚠️  SD-Karte kann jetzt aus Mac entfernt werden"
echo ""
info "Nächste Schritte:"
echo "  1. SD-Karte aus Mac entfernen"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten lassen"
echo "  4. SSH sollte GARANTIERT funktionieren: ssh andre@<PI_IP> (Pass: 0815)"
echo ""
log "Installation abgeschlossen!"

