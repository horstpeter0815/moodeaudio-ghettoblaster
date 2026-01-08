#!/bin/bash
# Simple Boot Logger - Writes to /var/log/boot-debug.log
# Can be retrieved via SSH ASAP

LOG_FILE="/var/log/boot-debug.log"

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" >> "$LOG_FILE"
    echo "$1" | systemd-cat -t boot-debug-logger
}

log "=== BOOT DEBUG LOGGER START ==="
log "Timestamp: $(date)"
log "Uptime: $(uptime 2>/dev/null || echo 'N/A')"
log ""

# Service Status
log "=== SERVICE STATUS ==="
systemctl list-units --type=service --state=failed --no-pager 2>/dev/null | head -20 >> "$LOG_FILE" || log "Failed to get failed services"
log ""

# Network Status
log "=== NETWORK STATUS ==="
log "Interfaces:"
ip link show 2>/dev/null >> "$LOG_FILE" || ifconfig 2>/dev/null >> "$LOG_FILE" || log "No network info"
log ""
log "IP Addresses:"
ip addr show 2>/dev/null >> "$LOG_FILE" || ifconfig 2>/dev/null >> "$LOG_FILE" || log "No IP info"
log ""

# NetworkManager Status
log "=== NETWORKMANAGER STATUS ==="
systemctl status NetworkManager --no-pager 2>&1 | head -15 >> "$LOG_FILE" || log "NetworkManager status failed"
log ""
systemctl status NetworkManager-wait-online --no-pager 2>&1 | head -15 >> "$LOG_FILE" || log "NetworkManager-wait-online status failed"
log ""

# SSH Status
log "=== SSH STATUS ==="
systemctl status ssh --no-pager 2>&1 | head -10 >> "$LOG_FILE" || systemctl status sshd --no-pager 2>&1 | head -10 >> "$LOG_FILE" || log "SSH status failed"
log ""
netstat -tuln 2>/dev/null | grep ":22 " >> "$LOG_FILE" || ss -tuln 2>/dev/null | grep ":22 " >> "$LOG_FILE" || log "Port 22 not found"
log ""

log "=== BOOT DEBUG LOGGER END ==="

