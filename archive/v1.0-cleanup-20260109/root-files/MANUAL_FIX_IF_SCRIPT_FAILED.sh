#!/bin/bash
# Manual fix if the boot script didn't work
# Run this ON THE PI (via console or if you can get SSH access)

echo "=== MANUAL USER CREATION ==="
echo ""

# Create user if doesn't exist
if ! id -u andre &>/dev/null; then
    echo "Creating user 'andre'..."
    groupadd -g 1000 andre 2>/dev/null || true
    useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || {
        # Manual creation if useradd fails
        echo "andre:x:1000:1000:andre:/home/andre:/bin/bash" >> /etc/passwd
        echo "andre:x:1000:" >> /etc/group
        mkdir -p /home/andre
        chown 1000:1000 /home/andre
    }
    echo "✅ User created"
else
    echo "✅ User 'andre' already exists"
fi

# Set password
echo "Setting password..."
echo "andre:0815" | chpasswd 2>/dev/null || {
    echo "⚠️ chpasswd failed, trying manual method..."
    PASSWORD_HASH=$(openssl passwd -1 "0815" 2>/dev/null || echo "")
    if [ -n "$PASSWORD_HASH" ] && [ -f /etc/shadow ]; then
        # Remove old entry if exists
        sed -i '/^andre:/d' /etc/shadow 2>/dev/null || true
        # Add new entry
        echo "andre:${PASSWORD_HASH}:18500:0:99999:7:::" >> /etc/shadow
        echo "✅ Password set manually"
    fi
}

# Add sudo access
echo "andre ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/andre
chmod 0440 /etc/sudoers.d/andre
echo "✅ Sudo access granted"

# Create home directory
mkdir -p /home/andre/.ssh
chmod 700 /home/andre/.ssh
chown -R andre:andre /home/andre
echo "✅ Home directory configured"

# Enable SSH
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
echo "✅ SSH enabled"

echo ""
echo "✅ User 'andre' setup complete!"
echo "Try: ssh andre@10.10.11.39"
echo "Password: 0815"

