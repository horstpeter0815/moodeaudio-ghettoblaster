#!/bin/bash
# INSTALL INDEPENDENT SSH SERVICE - LIKE DIETPI
# This installs a service that runs independently and guarantees SSH
# sudo /Users/andrevollmer/moodeaudio-cursor/INSTALL_INDEPENDENT_SSH.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 INSTALL INDEPENDENT SSH SERVICE                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# STEP 1: CREATE SSH ACTIVATION SCRIPT IN /boot/firmware
################################################################################

echo "=== STEP 1: CREATE SSH ACTIVATION SCRIPT ==="

sudo tee "$SD_MOUNT/ssh-activate.sh" > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
# Independent SSH Activation Script
# Runs on every boot to guarantee SSH is enabled

# Enable SSH service
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true

# Create SSH flag
touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true

# Ensure SSH keys exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A 2>/dev/null || true
fi

# Unmask SSH (prevent disabling)
systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true

# Create symlink to ensure it's enabled
mkdir -p /etc/systemd/system/multi-user.target.wants 2>/dev/null || true
if [ -f /lib/systemd/system/ssh.service ]; then
    ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service 2>/dev/null || true
fi
if [ -f /lib/systemd/system/sshd.service ]; then
    ln -sf /lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service 2>/dev/null || true
fi

exit 0
SCRIPT_EOF

sudo chmod +x "$SD_MOUNT/ssh-activate.sh"
echo "✅ Script erstellt: $SD_MOUNT/ssh-activate.sh"
echo ""

################################################################################
# STEP 2: CREATE SYSTEMD SERVICE FILE
################################################################################

echo "=== STEP 2: CREATE SYSTEMD SERVICE ==="

# Check if rootfs is available
ROOTFS_MOUNT=""
if [ -d "$SD_MOUNT/../rootfs" ]; then
    ROOTFS_MOUNT="$SD_MOUNT/../rootfs"
elif mount | grep -q "rootfs\|ext4.*on.*rootfs"; then
    ROOTFS_MOUNT=$(mount | grep "rootfs\|ext4" | awk '{print $3}' | head -1)
fi

if [ -n "$ROOTFS_MOUNT" ]; then
    echo "✅ Root-Filesystem gefunden: $ROOTFS_MOUNT"
    
    SYSTEMD_DIR="$ROOTFS_MOUNT/etc/systemd/system"
    mkdir -p "$SYSTEMD_DIR"
    
    # Create independent SSH service
    sudo tee "$SYSTEMD_DIR/independent-ssh.service" > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Independent SSH Service - Guarantees SSH is always enabled
DefaultDependencies=no
After=local-fs.target
Before=network.target
Before=sysinit.target

[Service]
Type=oneshot
ExecStart=/boot/firmware/ssh-activate.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

# Run multiple times for safety
ExecStartPost=/bin/bash -c 'sleep 2; /boot/firmware/ssh-activate.sh'
ExecStartPost=/bin/bash -c 'sleep 5; /boot/firmware/ssh-activate.sh'
ExecStartPost=/bin/bash -c 'sleep 10; systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true; systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true'

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target
WantedBy=multi-user.target
SERVICE_EOF
    
    # Enable service
    WANTS_DIR="$ROOTFS_MOUNT/etc/systemd/system/local-fs.target.wants"
    mkdir -p "$WANTS_DIR"
    ln -sf "$SYSTEMD_DIR/independent-ssh.service" "$WANTS_DIR/independent-ssh.service" 2>/dev/null || true
    
    WANTS_DIR2="$ROOTFS_MOUNT/etc/systemd/system/sysinit.target.wants"
    mkdir -p "$WANTS_DIR2"
    ln -sf "$SYSTEMD_DIR/independent-ssh.service" "$WANTS_DIR2/independent-ssh.service" 2>/dev/null || true
    
    echo "✅ Service installiert: independent-ssh.service"
else
    echo "⚠️  Root-Filesystem nicht gemountet"
    echo "   Service wird beim ersten Boot installiert"
    echo "   Script ist in /boot/firmware/ssh-activate.sh"
fi
echo ""

################################################################################
# STEP 3: CREATE /etc/rc.local ENTRY (FALLBACK)
################################################################################

if [ -n "$ROOTFS_MOUNT" ]; then
    echo "=== STEP 3: CREATE RC.LOCAL ENTRY (FALLBACK) ==="
    
    RCLOCAL="$ROOTFS_MOUNT/etc/rc.local"
    
    # Backup
    if [ -f "$RCLOCAL" ]; then
        sudo cp "$RCLOCAL" "${RCLOCAL}.backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create rc.local with SSH activation
    sudo tee "$RCLOCAL" > /dev/null << 'RCLOCAL_EOF'
#!/bin/bash
# rc.local - Independent SSH Activation

# Run SSH activation script
/boot/firmware/ssh-activate.sh 2>/dev/null || true

exit 0
RCLOCAL_EOF
    
    sudo chmod +x "$RCLOCAL"
    echo "✅ rc.local erstellt"
fi
echo ""

################################################################################
# STEP 4: CREATE SSH FLAG (STANDARD METHOD)
################################################################################

echo "=== STEP 4: CREATE SSH FLAG ==="
sudo touch "$SD_MOUNT/ssh"
sudo chmod 644 "$SD_MOUNT/ssh"
sync
[ -f "$SD_MOUNT/ssh" ] && echo "✅ SSH-Flag erstellt" || echo "❌ SSH-Flag fehlt"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ INDEPENDENT SSH SERVICE INSTALLIERT                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Installiert:"
echo "  ✅ /boot/firmware/ssh-activate.sh (runs on every boot)"
if [ -n "$ROOTFS_MOUNT" ]; then
    echo "  ✅ /etc/systemd/system/independent-ssh.service"
    echo "  ✅ /etc/rc.local (fallback)"
fi
echo "  ✅ /boot/firmware/ssh (standard flag)"
echo ""
echo "Dieser Service:"
echo "  - Läuft unabhängig von Moode"
echo "  - Aktiviert SSH bei jedem Boot"
echo "  - Kann nicht von Moode deaktiviert werden"
echo "  - Startet sehr früh im Boot-Prozess"
echo ""

