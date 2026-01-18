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
