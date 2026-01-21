#!/bin/bash
# Boot Debug Logger - Comprehensive boot diagnostics
# Supports: start, monitor commands

LOG_FILE="/var/log/boot-debug.log"
BOOT_LOG="/boot/firmware/boot-debug.log"  # Backup on boot partition (always accessible)

log() {
    local msg="[$(date +%Y-%m-%d\ %H:%M:%S)] $1"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
    echo "$msg" >> "$BOOT_LOG" 2>/dev/null || true  # Also write to boot partition
    echo "$1" | systemd-cat -t boot-debug-logger 2>/dev/null || true
}

case "$1" in
    start)
        log "=== BOOT DEBUG LOGGER START ==="
        log "Timestamp: $(date)"
        log "Uptime: $(uptime 2>/dev/null || echo 'N/A')"
        log ""
        
        # Service Status
        log "=== SERVICE STATUS ==="
        systemctl list-units --type=service --state=failed --no-pager 2>/dev/null | head -20 >> "$LOG_FILE" 2>/dev/null || log "Failed to get failed services"
        log ""
        
        # Network Status
        log "=== NETWORK STATUS ==="
        log "Interfaces:"
        ip link show 2>/dev/null >> "$LOG_FILE" 2>/dev/null || ifconfig 2>/dev/null >> "$LOG_FILE" 2>/dev/null || log "No network info"
        log ""
        log "IP Addresses:"
        ip addr show 2>/dev/null >> "$LOG_FILE" 2>/dev/null || ifconfig 2>/dev/null >> "$LOG_FILE" 2>/dev/null || log "No IP info"
        log ""
        
        # NetworkManager Status
        log "=== NETWORKMANAGER STATUS ==="
        systemctl status NetworkManager --no-pager 2>&1 | head -15 >> "$LOG_FILE" 2>/dev/null || log "NetworkManager status failed"
        log ""
        systemctl status NetworkManager-wait-online --no-pager 2>&1 | head -15 >> "$LOG_FILE" 2>/dev/null || log "NetworkManager-wait-online status failed"
        log ""
        
        # SSH Status
        log "=== SSH STATUS ==="
        systemctl status ssh --no-pager 2>&1 | head -10 >> "$LOG_FILE" 2>/dev/null || systemctl status sshd --no-pager 2>&1 | head -10 >> "$LOG_FILE" 2>/dev/null || log "SSH status failed"
        log ""
        netstat -tuln 2>/dev/null | grep ":22 " >> "$LOG_FILE" 2>/dev/null || ss -tuln 2>/dev/null | grep ":22 " >> "$LOG_FILE" 2>/dev/null || log "Port 22 not found"
        log ""
        
        # Cloud-init Status
        log "=== CLOUD-INIT STATUS ==="
        systemctl status cloud-init.target --no-pager 2>&1 | head -10 >> "$LOG_FILE" 2>/dev/null || log "cloud-init.target status failed"
        log ""
        
        # Systemd Dependencies
        log "=== SYSTEMD DEPENDENCIES ==="
        systemctl list-dependencies cloud-init.target --no-pager 2>&1 | head -30 >> "$LOG_FILE" 2>/dev/null || log "Failed to get dependencies"
        log ""
        
        log "=== BOOT DEBUG LOGGER START COMPLETE ==="
        ;;
        
    monitor)
        log "=== BOOT DEBUG LOGGER MONITOR START ==="
        # Monitor for 10 minutes, log every 30 seconds
        for i in {1..20}; do
            sleep 30
            log "=== MONITOR CHECK $i/20 ==="
            
            # SSH Status
            if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
                log "SSH: ACTIVE"
            else
                log "SSH: INACTIVE"
            fi
            
            # Network Status
            ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
            if [ -n "$ETH0_IP" ]; then
                log "eth0 IP: $ETH0_IP"
            else
                log "eth0 IP: NONE"
            fi
            
            # NetworkManager Status
            if systemctl is-active --quiet NetworkManager; then
                log "NetworkManager: ACTIVE"
            else
                log "NetworkManager: INACTIVE"
            fi
            
            # cloud-init Status
            if systemctl is-active --quiet cloud-init.target; then
                log "cloud-init.target: ACTIVE"
            else
                log "cloud-init.target: INACTIVE"
            fi
            
            log ""
        done
        log "=== BOOT DEBUG LOGGER MONITOR COMPLETE ==="
        ;;
        
    *)
        echo "Usage: $0 {start|monitor}"
        exit 1
        ;;
esac

