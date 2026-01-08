#!/bin/bash
################################################################################
# CREATE USER VIA BOOT SCRIPT - Works when ExtFS doesn't show full rootfs
# 
# This creates a script on the boot partition that will create the user
# when the Pi boots. This works around ExtFS limitations.
#
# Usage: ./create-user-boot-script.sh
################################################################################

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD card not found"
    exit 1
fi

echo "=== CREATING USER CREATION SCRIPT ON BOOT PARTITION ==="
echo ""

# Create script that will run on boot to create user
cat > "$SD_MOUNT/create-user-on-boot.sh" << 'SCRIPT_EOF'
#!/bin/bash
# Create user "andre" on first boot
# This runs from /boot/firmware/create-user-on-boot.sh

MARKER="/var/lib/user-andre-created.done"

if [ -f "$MARKER" ]; then
    exit 0
fi

# Create user
if ! id -u andre &>/dev/null; then
    # Create group first
    groupadd -g 1000 andre 2>/dev/null || true
    
    # Create user
    useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || {
        # If useradd fails, try manual creation
        echo "andre:x:1000:1000:andre:/home/andre:/bin/bash" >> /etc/passwd
        echo "andre:x:1000:" >> /etc/group
        mkdir -p /home/andre
        chown 1000:1000 /home/andre
    }
    
    # Set password
    echo "andre:0815" | chpasswd 2>/dev/null || {
        # Manual password hash if chpasswd fails
        PASSWORD_HASH=$(openssl passwd -1 "0815" 2>/dev/null || echo '$6$rounds=5000$salt$...')
        if [ -f /etc/shadow ]; then
            echo "andre:${PASSWORD_HASH}:18500:0:99999:7:::" >> /etc/shadow
        fi
    }
    
    # Add to sudoers
    echo "andre ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/andre
    chmod 0440 /etc/sudoers.d/andre
    
    # Create home directory
    mkdir -p /home/andre/.ssh
    chmod 700 /home/andre/.ssh
    chown -R andre:andre /home/andre
    
    echo "✅ User 'andre' created"
fi

# Enable SSH
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
touch /boot/ssh 2>/dev/null || touch /boot/firmware/ssh 2>/dev/null || true

# Mark as done
touch "$MARKER"

exit 0
SCRIPT_EOF

chmod +x "$SD_MOUNT/create-user-on-boot.sh"
echo "✅ Created: $SD_MOUNT/create-user-on-boot.sh"

# Add to rc.local if it exists in rootfs
if [ -f "/Volumes/rootfs/etc/rc.local" ]; then
    echo "Adding to rc.local..."
    if ! grep -q "create-user-on-boot.sh" "/Volumes/rootfs/etc/rc.local"; then
        # Add before exit 0
        sed -i.bak '/^exit 0/i\
# Create user andre on first boot\
/boot/firmware/create-user-on-boot.sh 2>/dev/null || /boot/create-user-on-boot.sh 2>/dev/null || true
' "/Volumes/rootfs/etc/rc.local" 2>/dev/null || \
        sed -i '' '/^exit 0/i\
# Create user andre on first boot\
/boot/firmware/create-user-on-boot.sh 2>/dev/null || /boot/create-user-on-boot.sh 2>/dev/null || true
' "/Volumes/rootfs/etc/rc.local" 2>/dev/null || \
        echo "⚠️  Could not update rc.local (may need manual edit)"
        echo "✅ Added to rc.local"
    else
        echo "✅ Already in rc.local"
    fi
else
    echo "⚠️  rc.local not found in ExtFS mount"
fi

# Also create systemd service if we can
if [ -d "/Volumes/rootfs/etc/systemd/system" ]; then
    echo "Creating systemd service..."
    cat > "/Volumes/rootfs/etc/systemd/system/create-user-andre.service" << 'SERVICE_EOF'
[Unit]
Description=Create User andre on First Boot
After=local-fs.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/boot/firmware/create-user-on-boot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF
    
    # Enable it
    mkdir -p "/Volumes/rootfs/etc/systemd/system/multi-user.target.wants"
    ln -sf "/etc/systemd/system/create-user-andre.service" \
        "/Volumes/rootfs/etc/systemd/system/multi-user.target.wants/create-user-andre.service" 2>/dev/null || true
    echo "✅ Systemd service created"
fi

sync
echo ""
echo "✅ User creation script installed!"
echo ""
echo "On next boot, this will:"
echo "  1. Create user 'andre'"
echo "  2. Set password '0815'"
echo "  3. Enable SSH"
echo "  4. Configure sudo access"
echo ""
echo "After boot, test: ssh andre@10.10.11.39"


