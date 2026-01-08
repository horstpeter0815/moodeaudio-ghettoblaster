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

# Display Chain Status
log "=== DISPLAY CHAIN STATUS ==="
if [ -f "/sys/class/graphics/fb0/virtual_size" ]; then
    FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
    log "Framebuffer: $FB_SIZE"
fi
if command -v kmsprint >/dev/null 2>&1; then
    DRM_INFO=$(kmsprint 2>/dev/null | grep "FB" | head -1 || echo "")
    if [ -n "$DRM_INFO" ]; then
        log "DRM plane: $DRM_INFO"
    fi
fi
if [ -f "/boot/firmware/config.txt" ]; then
    HDMI_CVT=$(grep "^hdmi_cvt=" /boot/firmware/config.txt | cut -d'=' -f2 || echo "")
    if [ -n "$HDMI_CVT" ]; then
        log "Boot config hdmi_cvt: $HDMI_CVT"
    fi
fi
if [ -f "/boot/firmware/cmdline.txt" ]; then
    VIDEO_PARAM=$(grep -o "video=[^ ]*" /boot/firmware/cmdline.txt || echo "")
    if [ -n "$VIDEO_PARAM" ]; then
        log "Boot cmdline video: $VIDEO_PARAM"
    fi
fi
log ""

log "=== BOOT DEBUG LOGGER END ==="

