#!/bin/bash
# Independent SSH Activation Script
# Runs on every boot to guarantee SSH is enabled
# Located in /boot/firmware so it's always accessible

# FIRST: Create user 'andre' if it doesn't exist
/boot/firmware/create-user-on-boot.sh 2>/dev/null || /boot/create-user-on-boot.sh 2>/dev/null || true

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
