#!/bin/bash
# force-ssh-on.sh
# GARANTIERT SSH aktiviert - kann nicht deaktiviert werden

LOG_FILE="/var/log/force-ssh-on.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 2>/dev/null || true
}

log "=== FORCE-SSH-ON START ==="

# Method 1: Flag-Dateien
touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
log "✅ SSH flags created"

# Method 2: systemctl enable
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl enable ssh.service 2>/dev/null || systemctl enable sshd.service 2>/dev/null || true
log "✅ SSH service enabled"

# Method 3: Manueller Symlink
mkdir -p /etc/systemd/system/multi-user.target.wants 2>/dev/null || true
if [ -f /lib/systemd/system/ssh.service ]; then
    ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service 2>/dev/null || true
    log "✅ SSH symlink created"
fi
if [ -f /lib/systemd/system/sshd.service ]; then
    ln -sf /lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service 2>/dev/null || true
    log "✅ SSHD symlink created"
fi

# Method 4: Unmask
systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true
log "✅ SSH unmasked"

# Method 5: Start
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
log "✅ SSH started"

# Method 6: Restart alle 10 Sekunden für erste Minute
for i in {1..6}; do
    sleep 10
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
    log "✅ SSH re-enabled (iteration $i)"
done &

# Method 7: SSH Keys generieren falls fehlen
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A 2>/dev/null || true
    log "✅ SSH keys generated"
fi

# Method 8: SSH Config sicherstellen
mkdir -p /etc/ssh 2>/dev/null || true
if [ ! -f /etc/ssh/sshd_config ]; then
    ssh-keygen -A 2>/dev/null || true
    log "✅ SSH config created"
fi

# Method 9: Port 22 sicherstellen
if [ -f /etc/ssh/sshd_config ]; then
    sed -i "s/#Port 22/Port 22/" /etc/ssh/sshd_config 2>/dev/null || true
    sed -i "s/Port [0-9]*/Port 22/" /etc/ssh/sshd_config 2>/dev/null || true
    # PasswordAuthentication sicherstellen
    sed -i "s/#PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config 2>/dev/null || true
    sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config 2>/dev/null || true
    log "✅ SSH config updated (Port 22, PasswordAuthentication)"
fi

# Method 10: Firewall-Regeln (falls vorhanden)
ufw allow 22/tcp 2>/dev/null || true
iptables -A INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
log "✅ Firewall rules added"

# Method 11: Permissions sicherstellen
if [ -f /etc/ssh/sshd_config ]; then
    chmod 600 /etc/ssh/sshd_config 2>/dev/null || true
fi
if [ -d /etc/ssh ]; then
    chmod 644 /etc/ssh/*.pub 2>/dev/null || true
    chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null || true
fi
log "✅ Permissions set"

log "=== FORCE-SSH-ON END ==="
