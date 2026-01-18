#!/bin/bash
################################################################################
# CREATE USER IN ROOTFS - Run this with your EXT4 reading software
# 
# This script creates user "andre" directly in the rootfs filesystem.
# Run this when you have the rootfs mounted with your EXT4 tool.
#
# Usage: 
#   1. Mount rootfs with your EXT4 tool
#   2. Set ROOTFS_MOUNT to the mount point
#   3. Run: ./create-user-in-rootfs.sh
################################################################################

# Set this to where your EXT4 tool mounted the rootfs
ROOTFS_MOUNT="${1:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS_MOUNT" ]; then
    echo "❌ Rootfs not found at: $ROOTFS_MOUNT"
    echo ""
    echo "Usage: ./create-user-in-rootfs.sh [MOUNT_POINT]"
    echo "Example: ./create-user-in-rootfs.sh /Volumes/rootfs"
    exit 1
fi

if [ ! -f "$ROOTFS_MOUNT/etc/passwd" ]; then
    echo "❌ /etc/passwd not found - is this really the rootfs?"
    echo "   Checked: $ROOTFS_MOUNT/etc/passwd"
    exit 1
fi

echo "=== CREATING USER 'andre' IN ROOTFS ==="
echo "Rootfs: $ROOTFS_MOUNT"
echo ""

# Check if user already exists
if grep -q "^andre:" "$ROOTFS_MOUNT/etc/passwd" 2>/dev/null; then
    echo "⚠️  User 'andre' already exists in /etc/passwd"
    read -p "Update anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Create password hash for "0815"
echo "Creating password hash..."
PASSWORD_HASH=$(openssl passwd -1 "0815" 2>/dev/null)
if [ -z "$PASSWORD_HASH" ]; then
    # Fallback: use a known hash format
    PASSWORD_HASH='$6$rounds=5000$salt$...'
    echo "⚠️  Using placeholder hash - password may need to be set after boot"
fi

# Backup files
echo "Backing up files..."
cp "$ROOTFS_MOUNT/etc/passwd" "$ROOTFS_MOUNT/etc/passwd.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
cp "$ROOTFS_MOUNT/etc/group" "$ROOTFS_MOUNT/etc/group.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
if [ -f "$ROOTFS_MOUNT/etc/shadow" ]; then
    cp "$ROOTFS_MOUNT/etc/shadow" "$ROOTFS_MOUNT/etc/shadow.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
fi

# Add user to /etc/passwd
echo "Adding user to /etc/passwd..."
if ! grep -q "^andre:" "$ROOTFS_MOUNT/etc/passwd" 2>/dev/null; then
    echo "andre:x:1000:1000:andre:/home/andre:/bin/bash" >> "$ROOTFS_MOUNT/etc/passwd"
    echo "✅ User added to /etc/passwd"
else
    # Update existing entry
    sed -i.bak 's/^andre:.*/andre:x:1000:1000:andre:\/home\/andre:\/bin\/bash/' "$ROOTFS_MOUNT/etc/passwd" 2>/dev/null || \
    sed -i '' 's/^andre:.*/andre:x:1000:1000:andre:\/home\/andre:\/bin\/bash/' "$ROOTFS_MOUNT/etc/passwd" 2>/dev/null || \
    echo "⚠️  Could not update /etc/passwd (may need manual edit)"
fi

# Add group to /etc/group
echo "Adding group to /etc/group..."
if [ -f "$ROOTFS_MOUNT/etc/group" ]; then
    if ! grep -q "^andre:" "$ROOTFS_MOUNT/etc/group" 2>/dev/null; then
        echo "andre:x:1000:" >> "$ROOTFS_MOUNT/etc/group"
        echo "✅ Group added to /etc/group"
    else
        echo "✅ Group already exists"
    fi
else
    echo "⚠️  /etc/group not found - creating it"
    echo "root:x:0:" > "$ROOTFS_MOUNT/etc/group"
    echo "andre:x:1000:" >> "$ROOTFS_MOUNT/etc/group"
    echo "✅ /etc/group created"
fi

# Add password to /etc/shadow
echo "Adding password to /etc/shadow..."
if [ -f "$ROOTFS_MOUNT/etc/shadow" ]; then
    if ! grep -q "^andre:" "$ROOTFS_MOUNT/etc/shadow" 2>/dev/null; then
        # Format: username:password_hash:last_change:min:max:warn:inactive:expire
        echo "andre:${PASSWORD_HASH}:18500:0:99999:7:::" >> "$ROOTFS_MOUNT/etc/shadow"
        echo "✅ Password added to /etc/shadow"
    else
        # Update password
        sed -i.bak "s/^andre:[^:]*/andre:${PASSWORD_HASH}/" "$ROOTFS_MOUNT/etc/shadow" 2>/dev/null || \
        sed -i '' "s/^andre:[^:]*/andre:${PASSWORD_HASH}/" "$ROOTFS_MOUNT/etc/shadow" 2>/dev/null || \
        echo "⚠️  Could not update password (may need manual edit)"
    fi
else
    echo "⚠️  /etc/shadow not found - password will need to be set after boot"
fi

# Create home directory
echo "Creating home directory..."
mkdir -p "$ROOTFS_MOUNT/home/andre"
chmod 755 "$ROOTFS_MOUNT/home/andre" 2>/dev/null || true
echo "✅ Home directory created"

# Create .ssh directory
mkdir -p "$ROOTFS_MOUNT/home/andre/.ssh"
chmod 700 "$ROOTFS_MOUNT/home/andre/.ssh" 2>/dev/null || true
echo "✅ .ssh directory created"

# Add sudo access
echo "Configuring sudo access..."
mkdir -p "$ROOTFS_MOUNT/etc/sudoers.d"
echo "andre ALL=(ALL) NOPASSWD: ALL" > "$ROOTFS_MOUNT/etc/sudoers.d/andre"
chmod 0440 "$ROOTFS_MOUNT/etc/sudoers.d/andre" 2>/dev/null || true
echo "✅ Sudo access configured"

# Enable SSH in rc.local if it exists
if [ -f "$ROOTFS_MOUNT/etc/rc.local" ]; then
    if ! grep -q "systemctl.*ssh" "$ROOTFS_MOUNT/etc/rc.local"; then
        echo "Adding SSH activation to rc.local..."
        # Add before exit 0
        sed -i.bak '/^exit 0/i\
# Enable SSH\
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true\
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true\
touch /boot/ssh 2>/dev/null || touch /boot/firmware/ssh 2>/dev/null || true
' "$ROOTFS_MOUNT/etc/rc.local" 2>/dev/null || \
        sed -i '' '/^exit 0/i\
# Enable SSH\
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true\
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true\
touch /boot/ssh 2>/dev/null || touch /boot/firmware/ssh 2>/dev/null || true
' "$ROOTFS_MOUNT/etc/rc.local" 2>/dev/null || \
        echo "⚠️  Could not update rc.local"
        echo "✅ SSH activation added to rc.local"
    fi
fi

echo ""
echo "✅ User 'andre' created in rootfs!"
echo ""
echo "User: andre"
echo "Password: 0815"
echo "UID: 1000"
echo "GID: 1000"
echo "Sudo: Enabled (no password)"
echo ""
echo "Next: Boot Pi and test SSH:"
echo "  ssh andre@10.10.11.39"


