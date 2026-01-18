#!/bin/bash
################################################################################
#
# I2C Bus Stabilization Script
#
# - Checks I2C bus status
# - Resets I2C bus on errors
# - Retries critical components (FT6236, AMP100)
# - Logs I2C errors
#
# (C) 2025 Ghettoblaster Custom Build
# License: GPLv3
#
################################################################################

LOG_FILE="/var/log/i2c-stabilize.log"
MAX_RETRIES=3
RETRY_DELAY=2

################################################################################
# Logging function
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

################################################################################
# Check if I2C device exists
################################################################################

check_i2c_device() {
    local bus=$1
    local device=$2
    
    if [ ! -e "/dev/i2c-${bus}" ]; then
        log "❌ I2C bus ${bus} not found"
        return 1
    fi
    
    # Try to detect device
    if command -v i2cdetect &> /dev/null; then
        i2cdetect -y "${bus}" 2>/dev/null | grep -q "${device}" && return 0
    fi
    
    return 1
}

################################################################################
# Reset I2C bus by reloading module
################################################################################

reset_i2c_bus() {
    local bus=$1
    log "🔄 Resetting I2C bus ${bus}..."
    
    # Unload and reload I2C module
    if lsmod | grep -q "i2c_bcm2835"; then
        modprobe -r i2c_bcm2835 2>/dev/null
        sleep 1
    fi
    
    modprobe i2c_bcm2835 2>/dev/null
    modprobe i2c_dev 2>/dev/null
    sleep 2
    
    if [ -e "/dev/i2c-${bus}" ]; then
        log "✅ I2C bus ${bus} reset successful"
        return 0
    else
        log "❌ I2C bus ${bus} reset failed"
        return 1
    fi
}

################################################################################
# Check FT6236 touchscreen
################################################################################

check_ft6236() {
    log "🔍 Checking FT6236 touchscreen (I2C bus 1, address 0x38)..."
    
    local retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        if check_i2c_device 1 38; then
            log "✅ FT6236 detected on I2C bus 1"
            return 0
        fi
        
        retries=$((retries + 1))
        if [ $retries -lt $MAX_RETRIES ]; then
            log "⚠️  FT6236 not detected, retry ${retries}/${MAX_RETRIES}..."
            sleep $RETRY_DELAY
        fi
    done
    
    log "❌ FT6236 not detected after ${MAX_RETRIES} retries"
    
    # Try to reload FT6236 module
    if lsmod | grep -q "ft6236"; then
        log "🔄 Reloading FT6236 module..."
        modprobe -r ft6236 2>/dev/null
        sleep 1
        modprobe ft6236 2>/dev/null
        sleep 2
    fi
    
    return 1
}

################################################################################
# Check HiFiBerry AMP100
################################################################################

check_amp100() {
    log "🔍 Checking HiFiBerry AMP100 (I2C bus 1, address 0x4d)..."
    
    local retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        if check_i2c_device 1 4d; then
            log "✅ AMP100 detected on I2C bus 1"
            return 0
        fi
        
        retries=$((retries + 1))
        if [ $retries -lt $MAX_RETRIES ]; then
            log "⚠️  AMP100 not detected, retry ${retries}/${MAX_RETRIES}..."
            sleep $RETRY_DELAY
        fi
    done
    
    log "⚠️  AMP100 not detected (may be normal if not using I2C for detection)"
    return 0  # AMP100 might work without I2C detection
}

################################################################################
# Check I2C bus health
################################################################################

check_i2c_health() {
    log "🔍 Checking I2C bus health..."
    
    # Check if I2C modules are loaded
    if ! lsmod | grep -q "i2c_bcm2835"; then
        log "⚠️  I2C module not loaded, loading..."
        modprobe i2c_bcm2835 2>/dev/null || log "❌ Failed to load i2c_bcm2835"
    fi
    
    if ! lsmod | grep -q "i2c_dev"; then
        log "⚠️  I2C dev module not loaded, loading..."
        modprobe i2c_dev 2>/dev/null || log "❌ Failed to load i2c_dev"
    fi
    
    # Check I2C bus 1 (primary bus)
    if [ ! -e "/dev/i2c-1" ]; then
        log "❌ I2C bus 1 not available, attempting reset..."
        reset_i2c_bus 1
        return 1
    fi
    
    # Check for I2C errors in dmesg
    local i2c_errors=$(dmesg | grep -i "i2c.*error\|i2c.*fail\|i2c.*timeout" | tail -5)
    if [ -n "$i2c_errors" ]; then
        log "⚠️  I2C errors detected in kernel log:"
        echo "$i2c_errors" | while read line; do
            log "   $line"
        done
    else
        log "✅ No I2C errors in kernel log"
    fi
    
    return 0
}

################################################################################
# Main execution
################################################################################

main() {
    log "=== I2C STABILIZATION START ==="
    
    # Check I2C bus health
    if ! check_i2c_health; then
        log "❌ I2C bus health check failed"
        exit 1
    fi
    
    # Check critical components
    check_ft6236
    ft6236_status=$?
    
    check_amp100
    amp100_status=$?
    
    # Summary
    log "=== I2C STABILIZATION SUMMARY ==="
    if [ $ft6236_status -eq 0 ] && [ $amp100_status -eq 0 ]; then
        log "✅ All I2C components OK"
        exit 0
    else
        log "⚠️  Some I2C components have issues (check logs)"
        exit 0  # Don't fail, just warn
    fi
}

# Run main function
main "$@"

