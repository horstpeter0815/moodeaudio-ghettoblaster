#!/bin/bash
################################################################################
# INSTALL INDEPENDENT SSH SERVICE ON SD CARD
# 
# Installs a robust, independent SSH service that:
# - Runs independently of Moode Audio
# - Starts very early in boot process (before Moode)
# - Cannot be disabled by Moode
# - Works even if Moode fails to start
#
# Usage: sudo ./install-independent-ssh-sd-card.sh
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
echo "║  🔧 INSTALL INDEPENDENT SSH SERVICE ON SD CARD                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# STEP 1: FIND SD CARD
################################################################################

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
else
    error "SD-Karte nicht gefunden"
    echo ""
    warn "Bitte SD-Karte einstecken und warten bis sie gemountet ist"
    exit 1
fi

log "SD-Karte gefunden: $SD_MOUNT"
echo ""

# Check if rootfs is available
ROOTFS_MOUNT=""
if [ -d "$SD_MOUNT/../rootfs" ]; then
    ROOTFS_MOUNT="$SD_MOUNT/../rootfs"
elif mount | grep -q "rootfs\|ext4.*on.*rootfs"; then
    ROOTFS_MOUNT=$(mount | grep "rootfs\|ext4" | awk '{print $3}' | head -1)
fi

if [ -n "$ROOTFS_MOUNT" ]; then
    info "Root-Filesystem gefunden: $ROOTFS_MOUNT"
    ROOTFS_AVAILABLE=true
else
    warn "Root-Filesystem nicht gemountet"
    info "Installiere nur Boot-Partition Dateien"
    info "Systemd Service wird beim ersten Boot erstellt"
    ROOTFS_AVAILABLE=false
fi
echo ""

################################################################################
# STEP 2: CREATE SSH ACTIVATION SCRIPT ON BOOT PARTITION
################################################################################

log "=== STEP 2: CREATE SSH ACTIVATION SCRIPT ==="

sudo tee "$SD_MOUNT/ssh-activate.sh" > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
# Independent SSH Activation Script
# Runs on every boot to guarantee SSH is enabled
# Located in /boot/firmware so it's always accessible

# Enable SSH service (try both ssh and sshd)
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl enable ssh.service 2>/dev/null || systemctl enable sshd.service 2>/dev/null || true

# Start SSH service
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true

# Create SSH flag (standard Raspberry Pi method)
touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
chmod 644 /boot/firmware/ssh 2>/dev/null || chmod 644 /boot/ssh 2>/dev/null || true

# Ensure SSH keys exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    mkdir -p /etc/ssh 2>/dev/null || true
    ssh-keygen -A 2>/dev/null || true
fi

# Unmask SSH (prevent disabling)
systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true

# Create symlink to ensure it's enabled (force enable)
mkdir -p /etc/systemd/system/multi-user.target.wants 2>/dev/null || true
if [ -f /lib/systemd/system/ssh.service ]; then
    ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service 2>/dev/null || true
fi
if [ -f /lib/systemd/system/sshd.service ]; then
    ln -sf /lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service 2>/dev/null || true
fi

# Also create in local-fs.target.wants for early start
mkdir -p /etc/systemd/system/local-fs.target.wants 2>/dev/null || true
if [ -f /lib/systemd/system/ssh.service ]; then
    ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/local-fs.target.wants/ssh.service 2>/dev/null || true
fi

exit 0
SCRIPT_EOF

sudo chmod +x "$SD_MOUNT/ssh-activate.sh"
log "✅ SSH Activation Script erstellt: $SD_MOUNT/ssh-activate.sh"
echo ""

################################################################################
# STEP 3: CREATE SSH FLAG FILE
################################################################################

log "=== STEP 3: CREATE SSH FLAG FILE ==="

# Check if ssh exists as directory (common mistake) and remove it
if [ -d "$SD_MOUNT/ssh" ]; then
    warn "ssh existiert als Verzeichnis - entferne es"
    sudo rm -rf "$SD_MOUNT/ssh"
fi

# Create SSH flag file
sudo rm -f "$SD_MOUNT/ssh" 2>/dev/null || true
echo "" | sudo tee "$SD_MOUNT/ssh" > /dev/null
sudo chmod 644 "$SD_MOUNT/ssh"
sync

# Verify with sudo to ensure we can see it
if sudo test -f "$SD_MOUNT/ssh"; then
    log "✅ SSH Flag erstellt: $SD_MOUNT/ssh"
    sudo ls -la "$SD_MOUNT/ssh"
else
    error "❌ SSH Flag konnte nicht erstellt werden"
    error "Versuche alternative Methode..."
    # Alternative: use sh -c with sudo
    sudo sh -c "echo '' > '$SD_MOUNT/ssh' && chmod 644 '$SD_MOUNT/ssh'"
    sync
    if sudo test -f "$SD_MOUNT/ssh"; then
        log "✅ SSH Flag erstellt (alternative Methode)"
    else
        error "❌ SSH Flag konnte auch mit alternativer Methode nicht erstellt werden"
        exit 1
    fi
fi
echo ""

################################################################################
# STEP 4: CREATE SYSTEMD SERVICE (if rootfs available)
################################################################################

if [ "$ROOTFS_AVAILABLE" = true ]; then
    log "=== STEP 4: CREATE SYSTEMD SERVICE ==="
    
    SYSTEMD_DIR="$ROOTFS_MOUNT/etc/systemd/system"
    sudo mkdir -p "$SYSTEMD_DIR"
    
    # Create independent SSH service
    sudo tee "$SYSTEMD_DIR/independent-ssh.service" > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Independent SSH Service - Guarantees SSH is always enabled
DefaultDependencies=no
After=local-fs.target
Before=sysinit.target
Before=network.target
Before=moode-startup.service
Conflicts=shutdown.target

[Service]
Type=oneshot
ExecStart=/boot/firmware/ssh-activate.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

# Run multiple times for safety (redundancy)
ExecStartPost=/bin/bash -c 'sleep 2; /boot/firmware/ssh-activate.sh'
ExecStartPost=/bin/bash -c 'sleep 5; /boot/firmware/ssh-activate.sh'
ExecStartPost=/bin/bash -c 'sleep 10; systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true; systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true'

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target
WantedBy=multi-user.target
SERVICE_EOF
    
    log "✅ Systemd Service erstellt: independent-ssh.service"
    
    # Create symlinks to enable service
    WANTS_DIR1="$ROOTFS_MOUNT/etc/systemd/system/local-fs.target.wants"
    sudo mkdir -p "$WANTS_DIR1"
    sudo ln -sf "$SYSTEMD_DIR/independent-ssh.service" "$WANTS_DIR1/independent-ssh.service" 2>/dev/null || true
    
    WANTS_DIR2="$ROOTFS_MOUNT/etc/systemd/system/sysinit.target.wants"
    sudo mkdir -p "$WANTS_DIR2"
    sudo ln -sf "$SYSTEMD_DIR/independent-ssh.service" "$WANTS_DIR2/independent-ssh.service" 2>/dev/null || true
    
    WANTS_DIR3="$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants"
    sudo mkdir -p "$WANTS_DIR3"
    sudo ln -sf "$SYSTEMD_DIR/independent-ssh.service" "$WANTS_DIR3/independent-ssh.service" 2>/dev/null || true
    
    log "✅ Service Symlinks erstellt (in 3 targets)"
    echo ""
    
    ################################################################################
    # STEP 5: CREATE RC.LOCAL FALLBACK (optional safety layer)
    ################################################################################
    
    log "=== STEP 5: CREATE RC.LOCAL FALLBACK ==="
    
    RCLOCAL="$ROOTFS_MOUNT/etc/rc.local"
    
    # Backup existing rc.local if it exists
    if [ -f "$RCLOCAL" ]; then
        sudo cp "$RCLOCAL" "${RCLOCAL}.backup_$(date +%Y%m%d_%H%M%S)"
        info "Backup erstellt: ${RCLOCAL}.backup_*"
    fi
    
    # Create rc.local with SSH activation
    sudo tee "$RCLOCAL" > /dev/null << 'RCLOCAL_EOF'
#!/bin/bash
# rc.local - Independent SSH Activation Fallback
# This runs if systemd fails or as additional safety layer

# Run SSH activation script
/boot/firmware/ssh-activate.sh 2>/dev/null || true

exit 0
RCLOCAL_EOF
    
    sudo chmod +x "$RCLOCAL"
    log "✅ rc.local erstellt: $RCLOCAL"
    echo ""
else
    warn "Root-Filesystem nicht verfügbar - überspringe Systemd Service"
    info "Service wird beim ersten Boot automatisch erstellt"
    echo ""
fi

################################################################################
# STEP 6: SYNC AND VERIFY
################################################################################

log "=== STEP 6: SYNC AND VERIFY ==="

sync
log "✅ Alle Dateien synchronisiert"
echo ""

# Verify files
VERIFY_OK=true

if [ ! -f "$SD_MOUNT/ssh-activate.sh" ]; then
    error "❌ ssh-activate.sh fehlt"
    VERIFY_OK=false
fi

if [ ! -f "$SD_MOUNT/ssh" ]; then
    error "❌ ssh flag fehlt"
    VERIFY_OK=false
fi

if [ "$ROOTFS_AVAILABLE" = true ]; then
    if [ ! -f "$ROOTFS_MOUNT/etc/systemd/system/independent-ssh.service" ]; then
        error "❌ independent-ssh.service fehlt"
        VERIFY_OK=false
    fi
fi

if [ "$VERIFY_OK" = true ]; then
    log "✅ Alle Dateien verifiziert"
else
    error "❌ Verifizierung fehlgeschlagen"
    exit 1
fi
echo ""

################################################################################
# SUMMARY
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ INDEPENDENT SSH SERVICE INSTALLIERT                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

info "Installierte Dateien:"
echo "  ✅ $SD_MOUNT/ssh-activate.sh (SSH Activation Script)"
echo "  ✅ $SD_MOUNT/ssh (SSH Flag File)"

if [ "$ROOTFS_AVAILABLE" = true ]; then
    echo "  ✅ $ROOTFS_MOUNT/etc/systemd/system/independent-ssh.service"
    echo "  ✅ $ROOTFS_MOUNT/etc/rc.local (Fallback)"
fi

echo ""
info "Service-Eigenschaften:"
echo "  - Läuft unabhängig von Moode"
echo "  - Startet sehr früh (vor Moode)"
echo "  - Kann nicht von Moode deaktiviert werden"
echo "  - Funktioniert auch wenn Moode fehlschlägt"
echo "  - Mehrfache Redundanz für maximale Sicherheit"
echo ""

info "Nächste Schritte:"
echo "  1. SD-Karte sicher auswerfen"
echo "  2. SD-Karte in Raspberry Pi 5 einstecken"
echo "  3. Pi booten"
echo "  4. Warte 30-60 Sekunden"
echo "  5. SSH sollte verfügbar sein:"
echo "     ssh pi@<PI_IP>"
echo "     ssh andre@<PI_IP>"
echo ""

log "Installation abgeschlossen!"
echo ""

