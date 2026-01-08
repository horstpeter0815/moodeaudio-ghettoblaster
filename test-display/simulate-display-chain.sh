#!/bin/bash
################################################################################
#
# DISPLAY CHAIN SIMULATOR
#
# Simulates each layer of the display stack:
# - Boot config parser
# - Framebuffer initialization
# - DRM/KMS plane setup
# - X11 server startup
# - xrandr operations
# - Chromium launch
#
################################################################################

set -e

LOG_FILE="/var/log/display-chain/simulation.log"
SESSION_ID="sim-$(date +%s)"
CORRELATION_ID=""

log() {
    local layer="$1"
    local event_type="$2"
    local message="$3"
    local data="$4"
    local timestamp=$(date +%s%N)
    
    echo "{\"id\":\"log_${timestamp}_$$\",\"timestamp\":${timestamp},\"layer\":\"${layer}\",\"event_type\":\"${event_type}\",\"message\":\"${message}\",\"data\":${data},\"sessionId\":\"${SESSION_ID}\",\"correlationId\":\"${CORRELATION_ID}\"}" >> "$LOG_FILE"
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [${layer}] [${event_type}] ${message}" | tee -a "$LOG_FILE"
}

# Initialize correlation ID
CORRELATION_ID="corr-$(date +%s)"

log "boot" "init" "Display chain simulation started" "{\"sessionId\":\"${SESSION_ID}\",\"correlationId\":\"${CORRELATION_ID}\"}"

# Step 1: Parse boot configuration
log "boot" "config" "Parsing boot configuration" "{}"
if [ -f "/boot-config/config.txt" ]; then
    HDMI_CVT=$(grep "^hdmi_cvt=" /boot-config/config.txt | cut -d'=' -f2 || echo "")
    HDMI_GROUP=$(grep "^hdmi_group=" /boot-config/config.txt | cut -d'=' -f2 || echo "")
    HDMI_MODE=$(grep "^hdmi_mode=" /boot-config/config.txt | cut -d'=' -f2 || echo "")
    log "boot" "config" "Parsed config.txt" "{\"hdmi_cvt\":\"${HDMI_CVT}\",\"hdmi_group\":\"${HDMI_GROUP}\",\"hdmi_mode\":\"${HDMI_MODE}\"}"
else
    log "boot" "config" "config.txt not found, using defaults" "{\"hdmi_cvt\":\"400 1280 60 6 0 0 0\"}"
    HDMI_CVT="400 1280 60 6 0 0 0"
fi

if [ -f "/boot-config/cmdline.txt" ]; then
    VIDEO_PARAM=$(grep -o "video=[^ ]*" /boot-config/cmdline.txt || echo "")
    log "boot" "config" "Parsed cmdline.txt" "{\"video\":\"${VIDEO_PARAM}\"}"
else
    log "boot" "config" "cmdline.txt not found, using defaults" "{\"video\":\"HDMI-A-1:400x1280M@60,rotate=90\"}"
    VIDEO_PARAM="HDMI-A-1:400x1280M@60,rotate=90"
fi

# Step 2: Simulate framebuffer initialization
log "framebuffer" "init" "Initializing framebuffer" "{}"
# Extract resolution from HDMI_CVT or VIDEO_PARAM
if [ -n "$HDMI_CVT" ]; then
    FB_WIDTH=$(echo "$HDMI_CVT" | awk '{print $1}')
    FB_HEIGHT=$(echo "$HDMI_CVT" | awk '{print $2}')
elif echo "$VIDEO_PARAM" | grep -q "400x1280"; then
    FB_WIDTH="400"
    FB_HEIGHT="1280"
else
    FB_WIDTH="1280"
    FB_HEIGHT="400"
fi
log "framebuffer" "ready" "Framebuffer initialized" "{\"width\":${FB_WIDTH},\"height\":${FB_HEIGHT},\"size\":\"${FB_WIDTH}x${FB_HEIGHT}\"}"

# Step 3: Simulate DRM/KMS plane setup
log "drm" "init" "Initializing DRM/KMS plane" "{}"
# DRM typically defaults to EDID mode (400x1280 for portrait display)
DRM_WIDTH="400"
DRM_HEIGHT="1280"
log "drm" "ready" "DRM plane initialized" "{\"width\":${DRM_WIDTH},\"height\":${DRM_HEIGHT},\"size\":\"${DRM_WIDTH}x${DRM_HEIGHT}\"}"

# Check for mismatch
if [ "$FB_WIDTH" != "$DRM_WIDTH" ] || [ "$FB_HEIGHT" != "$DRM_HEIGHT" ]; then
    log "drm" "error" "Mismatch detected between framebuffer and DRM" "{\"fb\":\"${FB_WIDTH}x${FB_HEIGHT}\",\"drm\":\"${DRM_WIDTH}x${DRM_HEIGHT}\"}"
fi

# Step 4: Simulate X11 server startup
log "x11" "init" "Starting X11 server" "{}"
sleep 1
log "x11" "ready" "X11 server started" "{\"display\":\":0\"}"

# Step 5: Simulate xrandr operations
log "xrandr" "init" "Applying xrandr configuration" "{}"
# Check if rotation is needed (Forum solution: rotate left for portrait->landscape)
if echo "$VIDEO_PARAM" | grep -q "rotate=90" || [ "$FB_WIDTH" = "400" ] && [ "$FB_HEIGHT" = "1280" ]; then
    X11_ROTATION="left"
    X11_WIDTH="1280"
    X11_HEIGHT="400"
    log "xrandr" "config" "Applying rotation" "{\"mode\":\"${DRM_WIDTH}x${DRM_HEIGHT}\",\"rotation\":\"${X11_ROTATION}\",\"result\":\"${X11_WIDTH}x${X11_HEIGHT}\"}"
else
    X11_ROTATION="normal"
    X11_WIDTH="$DRM_WIDTH"
    X11_HEIGHT="$DRM_HEIGHT"
    log "xrandr" "config" "No rotation applied" "{\"mode\":\"${DRM_WIDTH}x${DRM_HEIGHT}\",\"rotation\":\"${X11_ROTATION}\"}"
fi
log "xrandr" "ready" "xrandr configuration complete" "{\"width\":${X11_WIDTH},\"height\":${X11_HEIGHT},\"rotation\":\"${X11_ROTATION}\"}"

# Step 6: Simulate Chromium launch
log "chromium" "init" "Launching Chromium" "{}"
# Chromium window size should match DRM plane (before rotation)
CHROMIUM_WIDTH="$DRM_WIDTH"
CHROMIUM_HEIGHT="$DRM_HEIGHT"
log "chromium" "config" "Chromium window configuration" "{\"width\":${CHROMIUM_WIDTH},\"height\":${CHROMIUM_HEIGHT},\"size\":\"${CHROMIUM_WIDTH}x${CHROMIUM_HEIGHT}\"}"
sleep 1
log "chromium" "ready" "Chromium launched" "{\"window\":\"${CHROMIUM_WIDTH}x${CHROMIUM_HEIGHT}\",\"display\":\"${X11_WIDTH}x${X11_HEIGHT}\",\"rotation\":\"${X11_ROTATION}\"}"

# Final state check
log "system" "state" "Final state snapshot" "{\"framebuffer\":\"${FB_WIDTH}x${FB_HEIGHT}\",\"drm\":\"${DRM_WIDTH}x${DRM_HEIGHT}\",\"x11\":\"${X11_WIDTH}x${X11_HEIGHT}\",\"chromium\":\"${CHROMIUM_WIDTH}x${CHROMIUM_HEIGHT}\",\"rotation\":\"${X11_ROTATION}\"}"

# Check for mismatches
MISMATCHES=0
if [ "$FB_WIDTH" != "$DRM_WIDTH" ] || [ "$FB_HEIGHT" != "$DRM_HEIGHT" ]; then
    log "system" "error" "FB-DRM mismatch" "{\"fb\":\"${FB_WIDTH}x${FB_HEIGHT}\",\"drm\":\"${DRM_WIDTH}x${DRM_HEIGHT}\"}"
    MISMATCHES=$((MISMATCHES + 1))
fi

if [ "$X11_WIDTH" != "$CHROMIUM_WIDTH" ] && [ "$X11_ROTATION" = "normal" ]; then
    log "system" "error" "X11-Chromium mismatch (no rotation)" "{\"x11\":\"${X11_WIDTH}x${X11_HEIGHT}\",\"chromium\":\"${CHROMIUM_WIDTH}x${CHROMIUM_HEIGHT}\"}"
    MISMATCHES=$((MISMATCHES + 1))
fi

if [ "$MISMATCHES" -eq 0 ]; then
    log "system" "success" "All layers synchronized" "{}"
else
    log "system" "error" "Mismatches detected" "{\"count\":${MISMATCHES}}"
fi

log "boot" "complete" "Display chain simulation complete" "{\"mismatches\":${MISMATCHES}}"

