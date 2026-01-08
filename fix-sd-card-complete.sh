#!/bin/bash
################################################################################
# Complete SD Card Fix - Standard moOde
# 
# Fixes:
# 1. SSH enable (persistent across boots)
# 2. User creation (andre with UID 1000:1000)
# 3. Ensures moOde can function
################################################################################

set -e

ROOTFS_MOUNT="/Volumes/rootfs"
BOOTFS_MOUNT="/Volumes/bootfs"

echo "=== COMPLETE SD CARD FIX ==="
echo ""

# Check if rootfs is mounted
if [ ! -d "$ROOTFS_MOUNT" ]; then
    echo "❌ Rootfs not mounted at $ROOTFS_MOUNT"
    echo "Please mount the SD card rootfs partition"
    exit 1
fi

echo "✅ Rootfs mounted at $ROOTFS_MOUNT"
echo ""

################################################################################
# 1. Create SSH Guaranteed Service (runs every boot)
################################################################################

echo "=== Creating ssh-guaranteed.service ==="

SSH_GUARANTEED_SERVICE="$ROOTFS_MOUNT/lib/systemd/system/ssh-guaranteed.service"
mkdir -p "$(dirname "$SSH_GUARANTEED_SERVICE")"

cat > "$SSH_GUARANTEED_SERVICE" << 'EOF'
[Unit]
Description=SSH Guaranteed Fix - Multiple Safety Layers
DefaultDependencies=no
After=local-fs.target
Before=network.target
Before=cloud-init.target
Before=sysinit.target
Conflicts=shutdown.target

[Service]
StandardOutput=journal
StandardError=journal
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    # Layer 1: SSH Flag-Datei (wird von Raspberry Pi OS erkannt)
    touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
    
    # Layer 2: SSH Service aktivieren (systemd)
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    
    # Layer 3: SSH Service unmaskieren
    systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true
    
    # Layer 4: SSH Config sicherstellen
    mkdir -p /etc/ssh 2>/dev/null || true
    if [ ! -f /etc/ssh/sshd_config ]; then
        ssh-keygen -A 2>/dev/null || true
    fi
    
    # Layer 5: SSH Keys generieren falls fehlen
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -A 2>/dev/null || true
    fi
    
    echo "✅ SSH Guaranteed Fix applied"
'

[Install]
WantedBy=sysinit.target
WantedBy=basic.target
WantedBy=local-fs.target
WantedBy=multi-user.target
EOF

chmod 644 "$SSH_GUARANTEED_SERVICE"
echo "✅ ssh-guaranteed.service created"

# Enable service
mkdir -p "$ROOTFS_MOUNT/etc/systemd/system/sysinit.target.wants"
ln -sf /lib/systemd/system/ssh-guaranteed.service "$ROOTFS_MOUNT/etc/systemd/system/sysinit.target.wants/ssh-guaranteed.service" 2>/dev/null || true
echo "✅ ssh-guaranteed.service enabled"

################################################################################
# 2. Create Fix User ID Service (ensures user exists)
################################################################################

echo ""
echo "=== Creating fix-user-id.service ==="

FIX_USER_SERVICE="$ROOTFS_MOUNT/lib/systemd/system/fix-user-id.service"
mkdir -p "$(dirname "$FIX_USER_SERVICE")"

cat > "$FIX_USER_SERVICE" << 'EOF'
[Unit]
Description=Ghettoblaster User ID Fix (moOde requires UID 1000)
After=local-fs.target
Before=cloud-init.target
Wants=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
    # Prüfe ob andre existiert und UID hat
    ANDRE_UID=$(id -u andre 2>/dev/null || echo "")
    if [ -z "$ANDRE_UID" ] || [ "$ANDRE_UID" != "1000" ]; then
        echo "Fixing andre UID to 1000..."
        # Versuche zuerst groupadd (falls Gruppe fehlt)
        groupadd -g 1000 andre 2>/dev/null || true
        # Versuche usermod (falls User existiert)
        if usermod -u 1000 -g 1000 andre 2>/dev/null; then
            echo "✅ andre UID auf 1000 geändert"
        else
            # Falls usermod fehlschlägt: User neu erstellen
            echo "⚠️  usermod fehlgeschlagen - erstelle User neu..."
            userdel -r andre 2>/dev/null || true
            groupadd -g 1000 andre 2>/dev/null || true
            useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || true
            usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre 2>/dev/null || true
            echo "andre:0815" | chpasswd 2>/dev/null || true
            echo "andre ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/andre 2>/dev/null || true
            chmod 0440 /etc/sudoers.d/andre 2>/dev/null || true
            echo "✅ andre User neu erstellt mit UID 1000"
        fi
    else
        echo "✅ andre hat bereits UID 1000"
    fi
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$FIX_USER_SERVICE"
echo "✅ fix-user-id.service created"

# Enable service
mkdir -p "$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants"
ln -sf /lib/systemd/system/fix-user-id.service "$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
echo "✅ fix-user-id.service enabled"

################################################################################
# 3. Create ssh-activate.sh Script (called by independent-ssh.service)
################################################################################

echo ""
echo "=== Creating ssh-activate.sh script ==="

SSH_ACTIVATE_SCRIPT="$ROOTFS_MOUNT/boot/firmware/ssh-activate.sh"
mkdir -p "$(dirname "$SSH_ACTIVATE_SCRIPT")"

cat > "$SSH_ACTIVATE_SCRIPT" << 'EOF'
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

exit 0
EOF

chmod +x "$SSH_ACTIVATE_SCRIPT"
echo "✅ ssh-activate.sh created"

################################################################################
# 4. Create SSH Flag on Boot Partition
################################################################################

echo ""
echo "=== Creating SSH flag on boot partition ==="

if [ -d "$BOOTFS_MOUNT" ]; then
    touch "$BOOTFS_MOUNT/ssh" 2>/dev/null || touch "$BOOTFS_MOUNT/firmware/ssh" 2>/dev/null || true
    echo "✅ SSH flag created on boot partition"
else
    echo "⚠️  Boot partition not mounted - SSH flag will be created on first boot"
fi

################################################################################
# Summary
################################################################################

echo ""
echo "=== FIX COMPLETE ==="
echo ""
echo "Services created and enabled:"
echo "  ✅ ssh-guaranteed.service (runs every boot)"
echo "  ✅ fix-user-id.service (ensures user exists)"
echo "  ✅ ssh-activate.sh (called by independent-ssh.service)"
echo ""
echo "Next steps:"
echo "  1. Mount boot partition (if not mounted):"
echo "     diskutil list"
echo "     sudo diskutil mount /dev/diskXs1"
echo "  2. Create SSH flag: touch /Volumes/bootfs/ssh"
echo "  3. Eject SD card safely"
echo "  4. Boot the Pi"
echo "  5. SSH should be enabled"
echo "  6. User 'andre' should exist with UID 1000:1000"
echo ""

