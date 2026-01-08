#!/bin/bash
################################################################################
# CREATE USER AND SSH ON SD CARD - ROOT CAUSE FIX
# 
# This directly modifies the rootfs to:
# 1. Create user "andre" in /etc/passwd and /etc/shadow
# 2. Enable SSH service
# 3. Set up SSH properly
#
# This works on STANDARD moOde (no first-boot scripts needed)
#
# Usage: ./create-user-and-ssh-on-sd.sh
################################################################################

set -e

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD card not found"
    exit 1
fi

echo "=== CREATING USER AND SSH ON SD CARD ==="
echo ""

# Find rootfs
ROOTFS_MOUNT=""
if [ -d "$SD_MOUNT/../rootfs" ]; then
    ROOTFS_MOUNT="$SD_MOUNT/../rootfs"
elif mount | grep -q "ext4.*on.*rootfs"; then
    ROOTFS_MOUNT=$(mount | grep "ext4" | awk '{print $3}' | head -1)
else
    echo "⚠️  Rootfs not mounted. Trying to mount..."
    # Try to mount rootfs partition
    ROOTFS_DEVICE=$(diskutil list | grep -A 2 "disk4" | grep "Linux" | awk '{print "/dev/r"$NF}' | head -1)
    if [ -n "$ROOTFS_DEVICE" ]; then
        echo "Found rootfs device: $ROOTFS_DEVICE"
        echo "You may need to mount it manually or use a tool that can mount ext4"
    fi
fi

if [ -z "$ROOTFS_MOUNT" ] || [ ! -d "$ROOTFS_MOUNT" ]; then
    echo "❌ Cannot access rootfs. Options:"
    echo "  1. Mount rootfs manually"
    echo "  2. Use Linux VM to mount ext4 partition"
    echo "  3. Create user after boot via Web UI"
    exit 1
fi

echo "✅ Rootfs found: $ROOTFS_MOUNT"
echo ""

# Create user in /etc/passwd
echo "Creating user 'andre' in /etc/passwd..."
PASSWD_FILE="$ROOTFS_MOUNT/etc/passwd"
if ! grep -q "^andre:" "$PASSWD_FILE" 2>/dev/null; then
    # UID 1000, GID 1000, home /home/andre, shell /bin/bash
    echo "andre:x:1000:1000:andre:/home/andre:/bin/bash" >> "$PASSWD_FILE"
    echo "✅ User added to /etc/passwd"
else
    echo "✅ User already in /etc/passwd"
fi

# Create group in /etc/group
echo "Creating group 'andre' in /etc/group..."
GROUP_FILE="$ROOTFS_MOUNT/etc/group"
if ! grep -q "^andre:" "$GROUP_FILE" 2>/dev/null; then
    echo "andre:x:1000:" >> "$GROUP_FILE"
    echo "✅ Group added to /etc/group"
else
    echo "✅ Group already in /etc/group"
fi

# Create home directory
echo "Creating home directory..."
mkdir -p "$ROOTFS_MOUNT/home/andre"
chmod 755 "$ROOTFS_MOUNT/home/andre" 2>/dev/null || true
echo "✅ Home directory created"

# Create password hash for "0815"
# Using openssl to create password hash
PASSWORD_HASH=$(openssl passwd -1 "0815" 2>/dev/null || echo "\$6\$rounds=5000\$salt\$...")

# Add to /etc/shadow
echo "Adding password to /etc/shadow..."
SHADOW_FILE="$ROOTFS_MOUNT/etc/shadow"
if ! grep -q "^andre:" "$SHADOW_FILE" 2>/dev/null; then
    # Format: username:password_hash:last_change:min:max:warn:inactive:expire
    echo "andre:${PASSWORD_HASH}:18500:0:99999:7:::" >> "$SHADOW_FILE"
    echo "✅ Password added to /etc/shadow"
else
    echo "⚠️  User already in /etc/shadow (password may need updating)"
fi

# Add to sudoers
echo "Adding sudo access..."
SUDOERS_FILE="$ROOTFS_MOUNT/etc/sudoers.d/andre"
mkdir -p "$ROOTFS_MOUNT/etc/sudoers.d"
echo "andre ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"
echo "✅ Sudo access configured"

# Enable SSH
echo "Enabling SSH..."
SSH_FLAG="$SD_MOUNT/ssh"
touch "$SSH_FLAG" 2>/dev/null || echo "" > "$SSH_FLAG"
chmod 644 "$SSH_FLAG"
echo "✅ SSH flag created"

# Create SSH activation in rc.local
echo "Adding SSH activation to rc.local..."
RCLOCAL="$ROOTFS_MOUNT/etc/rc.local"
if [ ! -f "$RCLOCAL" ]; then
    cat > "$RCLOCAL" << 'EOF'
#!/bin/bash
# Enable SSH on every boot
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
touch /boot/ssh 2>/dev/null || touch /boot/firmware/ssh 2>/dev/null || true
exit 0
EOF
    chmod +x "$RCLOCAL"
    echo "✅ rc.local created"
else
    if ! grep -q "systemctl.*ssh" "$RCLOCAL"; then
        # Add SSH activation before exit
        sed -i.bak '/^exit 0/i\
# Enable SSH\
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true\
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true\
touch /boot/ssh 2>/dev/null || touch /boot/firmware/ssh 2>/dev/null || true
' "$RCLOCAL"
        echo "✅ SSH activation added to rc.local"
    else
        echo "✅ rc.local already has SSH activation"
    fi
fi

sync
echo ""
echo "✅ User 'andre' and SSH setup complete!"
echo ""
echo "User: andre"
echo "Password: 0815"
echo "Sudo: Enabled (no password)"
echo "SSH: Enabled"


