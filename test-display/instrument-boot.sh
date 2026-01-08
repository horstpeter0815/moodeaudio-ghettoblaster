#!/bin/bash
################################################################################
#
# BOOT SEQUENCE INSTRUMENTATION
#
# Hooks into boot sequence:
# - config.txt parsing → log FB configuration
# - cmdline.txt parsing → log video parameters
# - Kernel framebuffer init → log FB size
# - DRM initialization → log plane configuration
#
################################################################################

set -e

# Source the logger
source /scripts/display-chain-logger.sh 2>/dev/null || {
    # Fallback if logger not available
    LOG_FILE="/var/log/display-chain/boot.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    log() {
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" >> "$LOG_FILE"
    }
}

log_boot() {
    log "[BOOT] $*"
}

# Parse config.txt
if [ -f "/boot/firmware/config.txt" ]; then
    log_boot "Parsing config.txt"
    HDMI_CVT=$(grep "^hdmi_cvt=" /boot/firmware/config.txt | cut -d'=' -f2 || echo "")
    HDMI_GROUP=$(grep "^hdmi_group=" /boot/firmware/config.txt | cut -d'=' -f2 || echo "")
    HDMI_MODE=$(grep "^hdmi_mode=" /boot/firmware/config.txt | cut -d'=' -f2 || echo "")
    log_boot "config.txt parsed: hdmi_cvt=$HDMI_CVT, hdmi_group=$HDMI_GROUP, hdmi_mode=$HDMI_MODE"
    
    if [ -n "$HDMI_CVT" ]; then
        FB_WIDTH=$(echo "$HDMI_CVT" | awk '{print $1}')
        FB_HEIGHT=$(echo "$HDMI_CVT" | awk '{print $2}')
        log_boot "Framebuffer configuration: ${FB_WIDTH}x${FB_HEIGHT}"
    fi
fi

# Parse cmdline.txt
if [ -f "/boot/firmware/cmdline.txt" ]; then
    log_boot "Parsing cmdline.txt"
    VIDEO_PARAM=$(grep -o "video=[^ ]*" /boot/firmware/cmdline.txt || echo "")
    log_boot "cmdline.txt parsed: video=$VIDEO_PARAM"
    
    if echo "$VIDEO_PARAM" | grep -q "rotate="; then
        ROTATE=$(echo "$VIDEO_PARAM" | grep -o "rotate=[0-9]*" | cut -d'=' -f2)
        log_boot "Rotation parameter: $ROTATE"
    fi
fi

# Check framebuffer after kernel init
if [ -f "/sys/class/graphics/fb0/virtual_size" ]; then
    FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
    log_boot "Kernel framebuffer initialized: $FB_SIZE"
fi

# Check DRM after initialization
if command -v kmsprint >/dev/null 2>&1; then
    DRM_INFO=$(kmsprint 2>/dev/null | grep "FB" | head -1 || echo "")
    if [ -n "$DRM_INFO" ]; then
        log_boot "DRM plane initialized: $DRM_INFO"
    fi
fi

log_boot "Boot instrumentation complete"

