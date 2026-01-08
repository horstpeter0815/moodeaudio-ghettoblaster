#!/bin/bash
################################################################################
#
# DISPLAY CHAIN LOGGER
#
# Enhanced logger for display chain analysis
# Logs at every layer: boot, kernel, framebuffer, drm, x11, xrandr, chromium
#
################################################################################

LOG_FILE="/var/log/display-chain/chain.log"
SESSION_ID="session-$(date +%s)"
CORRELATION_ID=""

# Initialize correlation ID if not set
if [ -z "$CORRELATION_ID" ]; then
    CORRELATION_ID="corr-$(date +%s)"
fi

log() {
    local layer="$1"
    local event_type="$2"
    local message="$3"
    local data="${4:-{}}"
    local timestamp=$(date +%s%N)
    
    # JSON log entry
    echo "{\"id\":\"log_${timestamp}_$$\",\"timestamp\":${timestamp},\"layer\":\"${layer}\",\"event_type\":\"${event_type}\",\"message\":\"${message}\",\"data\":${data},\"sessionId\":\"${SESSION_ID}\",\"correlationId\":\"${CORRELATION_ID}\"}" >> "$LOG_FILE"
    
    # Human-readable log entry
    echo "[$(date +%Y-%m-%d\ %H:%M:%S.%N)] [${layer}] [${event_type}] ${message}" | tee -a "${LOG_FILE%.log}.human.log"
}

# Boot layer logging
log_boot() {
    local event_type="$1"
    local message="$2"
    local data="${3:-{}}"
    log "boot" "$event_type" "$message" "$data"
}

# Kernel/Framebuffer layer logging
log_framebuffer() {
    local event_type="$1"
    local message="$2"
    local data="${3:-{}}"
    log "framebuffer" "$event_type" "$message" "$data"
}

# DRM/KMS layer logging
log_drm() {
    local event_type="$1"
    local message="$2"
    local data="${3:-{}}"
    log "drm" "$event_type" "$message" "$data"
}

# X11 layer logging
log_x11() {
    local event_type="$1"
    local message="$2"
    local data="${3:-{}}"
    log "x11" "$event_type" "$message" "$data"
}

# xrandr layer logging
log_xrandr() {
    local event_type="$1"
    local message="$2"
    local data="${3:-{}}"
    log "xrandr" "$event_type" "$message" "$data"
}

# Chromium layer logging
log_chromium() {
    local event_type="$1"
    local message="$2"
    local data="${3:-{}}"
    log "chromium" "$event_type" "$message" "$data"
}

# State snapshot function
snapshot_state() {
    local layer="$1"
    local snapshot_data="$2"
    log "$layer" "snapshot" "State snapshot" "$snapshot_data"
}

# Export functions for use in other scripts
export -f log log_boot log_framebuffer log_drm log_x11 log_xrandr log_chromium snapshot_state
export LOG_FILE SESSION_ID CORRELATION_ID

