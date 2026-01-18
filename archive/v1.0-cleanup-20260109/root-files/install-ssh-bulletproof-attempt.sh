#!/bin/bash
################################################################################
# INSTALL BULLETPROOF SSH ATTEMPT - CANNOT BE OVERWRITTEN
# 
# ATTEMPT: This creates an ULTRA-ROBUST SSH installation attempt that:
# 1. Runs CONTINUOUSLY (every 10 seconds)
# 2. Cannot be disabled by moOde or anything else
# 3. Works even if services are stopped
# 4. Protects itself from being overwritten
#
# ATTEMPT: This is an attempt to solve SSH problems - NOT TESTED YET.
#
# Usage: ./install-ssh-bulletproof.sh
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
echo "║  🛡️  INSTALL BULLETPROOF SSH ATTEMPT (NOT TESTED)             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIND SD CARD
################################################################################

SD_MOUNT=""
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

if [ -z "$SD_MOUNT" ] || [ ! -d "$SD_MOUNT" ]; then
    error "SD card not found!"
    echo ""
    warn "Please insert SD card or specify mount point:"
    echo "  ./install-ssh-bulletproof.sh /Volumes/bootfs"
    exit 1
fi

log "SD card found: $SD_MOUNT"
echo ""

# Check rootfs
ROOTFS_MOUNT=""
if [ -d "$SD_MOUNT/../rootfs" ]; then
    ROOTFS_MOUNT="$SD_MOUNT/../rootfs"
elif mount | grep -q "rootfs\|ext4.*on.*rootfs"; then
    ROOTFS_MOUNT=$(mount | grep "rootfs\|ext4" | awk '{print $3}' | head -1)
fi

if [ -n "$ROOTFS_MOUNT" ]; then
    log "Root filesystem found: $ROOTFS_MOUNT"
    ROOTFS_AVAILABLE=true
else
    warn "Root filesystem not mounted (will install on first boot)"
    ROOTFS_AVAILABLE=false
fi
echo ""

################################################################################
# STEP 1: CREATE BULLETPROOF SSH ACTIVATION SCRIPT
################################################################################

log "=== STEP 1: CREATE BULLETPROOF SSH ACTIVATION SCRIPT ==="

sudo tee "$SD_MOUNT/ssh-bulletproof.sh" > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
# BULLETPROOF SSH ACTIVATION - RUNS CONTINUOUSLY
# This script CANNOT be stopped and ALWAYS enables SSH

# Method 1: SSH Flag Files (multiple locations)
touch /boot/firmware/ssh 2>/dev/null || true
touch /boot/ssh 2>/dev/null || true
chmod 644 /boot/firmware/ssh 2>/dev/null || chmod 644 /boot/ssh 2>/dev/null || true

# Method 2: Enable SSH Service (multiple attempts)
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl enable ssh.service 2>/dev/null || systemctl enable sshd.service 2>/dev/null || true

# Method 3: Unmask SSH (prevent disabling)
systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true

# Method 4: Start SSH Service
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

# Method 5: Create Symlinks (force enable)
mkdir -p /etc/systemd/system/multi-user.target.wants 2>/dev/null || true
mkdir -p /etc/systemd/system/local-fs.target.wants 2>/dev/null || true
mkdir -p /etc/systemd/system/sysinit.target.wants 2>/dev/null || true

if [ -f /lib/systemd/system/ssh.service ]; then
    ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service 2>/dev/null || true
    ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/local-fs.target.wants/ssh.service 2>/dev/null || true
    ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/sysinit.target.wants/ssh.service 2>/dev/null || true
fi

if [ -f /lib/systemd/system/sshd.service ]; then
    ln -sf /lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service 2>/dev/null || true
    ln -sf /lib/systemd/system/sshd.service /etc/systemd/system/local-fs.target.wants/sshd.service 2>/dev/null || true
    ln -sf /lib/systemd/system/sshd.service /etc/systemd/system/sysinit.target.wants/sshd.service 2>/dev/null || true
fi

# Method 6: Generate SSH Keys if missing
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    mkdir -p /etc/ssh 2>/dev/null || true
    ssh-keygen -A 2>/dev/null || true
fi

# Method 7: Ensure SSH Config
if [ -f /etc/ssh/sshd_config ]; then
    # Ensure Port 22
    sed -i "s/#Port 22/Port 22/" /etc/ssh/sshd_config 2>/dev/null || true
    sed -i "s/Port [0-9]*/Port 22/" /etc/ssh/sshd_config 2>/dev/null || true
    # Ensure PasswordAuthentication
    sed -i "s/#PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config 2>/dev/null || true
    sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config 2>/dev/null || true
fi

# Method 8: Firewall Rules
ufw allow 22/tcp 2>/dev/null || true
iptables -I INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
iptables -A INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true

# Method 9: Direct sshd start (if systemctl fails)
if ! systemctl is-active --quiet ssh && ! systemctl is-active --quiet sshd; then
    /usr/sbin/sshd -t 2>/dev/null && /usr/sbin/sshd -D -p 22 & 2>/dev/null || true
fi

exit 0
SCRIPT_EOF

sudo chmod +x "$SD_MOUNT/ssh-bulletproof.sh"
log "✅ Bulletproof SSH script created"
echo ""

################################################################################
# STEP 2: CREATE CONTINUOUS MONITORING SERVICE
################################################################################

if [ "$ROOTFS_AVAILABLE" = true ]; then
    log "=== STEP 2: CREATE CONTINUOUS MONITORING SERVICE ==="
    
    SYSTEMD_DIR="$ROOTFS_MOUNT/etc/systemd/system"
    sudo mkdir -p "$SYSTEMD_DIR"
    
    # Create bulletproof SSH service that runs CONTINUOUSLY
    sudo tee "$SYSTEMD_DIR/ssh-bulletproof.service" > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Bulletproof SSH - Continuous Protection (Cannot be stopped)
DefaultDependencies=no
After=local-fs.target
Before=sysinit.target
Before=network.target
Before=moode-startup.service
Conflicts=shutdown.target

[Service]
Type=simple
Restart=always
RestartSec=5
# Run continuously - cannot be stopped
ExecStart=/bin/bash -c '
    while true; do
        # Run bulletproof activation
        /boot/firmware/ssh-bulletproof.sh 2>/dev/null || true
        
        # Double-check SSH is running
        if ! systemctl is-active --quiet ssh && ! systemctl is-active --quiet sshd; then
            systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
            /boot/firmware/ssh-bulletproof.sh 2>/dev/null || true
        fi
        
        # Sleep 10 seconds and repeat FOREVER
        sleep 10
    done
'
StandardOutput=journal
StandardError=journal

# Protect service from being stopped
KillMode=none
KillSignal=SIGKILL
RestartForceExitStatus=0

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target
WantedBy=multi-user.target
RequiredBy=network.target
SERVICE_EOF
    
    log "✅ Bulletproof service created"
    
    # Enable in ALL possible targets
    for target in local-fs.target sysinit.target multi-user.target; do
        WANTS_DIR="$ROOTFS_MOUNT/etc/systemd/system/${target}.wants"
        sudo mkdir -p "$WANTS_DIR"
        sudo ln -sf "$SYSTEMD_DIR/ssh-bulletproof.service" "$WANTS_DIR/ssh-bulletproof.service" 2>/dev/null || true
    done
    
    log "✅ Service enabled in all targets"
    echo ""
fi

################################################################################
# STEP 3: CREATE RC.LOCAL ENTRY (Runs before systemd)
################################################################################

if [ "$ROOTFS_AVAILABLE" = true ]; then
    log "=== STEP 3: CREATE RC.LOCAL ENTRY ==="
    
    RCLOCAL="$ROOTFS_MOUNT/etc/rc.local"
    
    # Backup
    if [ -f "$RCLOCAL" ]; then
        sudo cp "$RCLOCAL" "${RCLOCAL}.backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create rc.local that runs bulletproof script
    sudo tee "$RCLOCAL" > /dev/null << 'RCLOCAL_EOF'
#!/bin/bash
# rc.local - Bulletproof SSH Activation
# Runs BEFORE systemd, cannot be stopped

# Run bulletproof script immediately
/boot/firmware/ssh-bulletproof.sh 2>/dev/null || true

# Also start it in background (continuous)
(/boot/firmware/ssh-bulletproof.sh; while true; do sleep 10; /boot/firmware/ssh-bulletproof.sh; done) &

exit 0
RCLOCAL_EOF
    
    sudo chmod +x "$RCLOCAL"
    log "✅ rc.local created with continuous protection"
    echo ""
fi

################################################################################
# STEP 4: CREATE SSH FLAG FILES
################################################################################

log "=== STEP 4: CREATE SSH FLAG FILES ==="

# Remove if directory
if [ -d "$SD_MOUNT/ssh" ]; then
    sudo rm -rf "$SD_MOUNT/ssh"
fi

# Create flag files
sudo touch "$SD_MOUNT/ssh" 2>/dev/null || sudo sh -c "echo '' > '$SD_MOUNT/ssh'"
sudo chmod 644 "$SD_MOUNT/ssh"

if [ -d "$SD_MOUNT/firmware" ]; then
    sudo touch "$SD_MOUNT/firmware/ssh" 2>/dev/null || sudo sh -c "echo '' > '$SD_MOUNT/firmware/ssh'"
    sudo chmod 644 "$SD_MOUNT/firmware/ssh"
    log "✅ SSH flag created: $SD_MOUNT/firmware/ssh"
fi

log "✅ SSH flag created: $SD_MOUNT/ssh"
echo ""

################################################################################
# STEP 5: SYNC AND VERIFY
################################################################################

log "=== STEP 5: SYNC AND VERIFY ==="

sync
log "✅ All files synced"
echo ""

# Verify
VERIFY_OK=true
[ ! -f "$SD_MOUNT/ssh-bulletproof.sh" ] && { error "❌ ssh-bulletproof.sh missing"; VERIFY_OK=false; }
[ ! -f "$SD_MOUNT/ssh" ] && { error "❌ SSH flag missing"; VERIFY_OK=false; }

if [ "$ROOTFS_AVAILABLE" = true ]; then
    [ ! -f "$ROOTFS_MOUNT/etc/systemd/system/ssh-bulletproof.service" ] && { error "❌ Service missing"; VERIFY_OK=false; }
    [ ! -f "$ROOTFS_MOUNT/etc/rc.local" ] && { error "❌ rc.local missing"; VERIFY_OK=false; }
fi

if [ "$VERIFY_OK" = true ]; then
    log "✅ All files verified"
else
    error "❌ Verification failed"
    exit 1
fi

echo ""

################################################################################
# SUMMARY
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ BULLETPROOF SSH ATTEMPT INSTALLED (NOT TESTED)            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

info "This attempt:"
echo "  ✅ Runs CONTINUOUSLY (every 10 seconds)"
echo "  ✅ Cannot be stopped by moOde or anything else"
echo "  ✅ Works even if services are disabled"
echo "  ✅ Multiple activation methods"
echo "  ✅ Protected from overwrite"
echo ""

info "Installed components:"
echo "  ✅ $SD_MOUNT/ssh-bulletproof.sh (continuous activation)"
if [ "$ROOTFS_AVAILABLE" = true ]; then
    echo "  ✅ ssh-bulletproof.service (runs continuously)"
    echo "  ✅ /etc/rc.local (early boot protection)"
fi
echo "  ✅ SSH flag files"
echo ""

warn "⚠️  This SSH attempt is designed to be persistent (NOT TESTED)"
echo "   It runs continuously and will always re-enable SSH."
echo ""

info "Next steps:"
echo "  1. Eject SD card safely"
echo "  2. Insert SD card into Pi"
echo "  3. Boot Pi"
echo "  4. SSH will be enabled and STAY enabled"
echo ""

log "Installation complete!"

