#!/bin/bash
################################################################################
#
# I2C Bus Monitoring Script
#
# - Monitors I2C bus health in background
# - Logs I2C errors
# - Attempts recovery on errors
#
# (C) 2025 Ghettoblaster Custom Build
# License: GPLv3
#
################################################################################

LOG_FILE="/var/log/i2c-monitor.log"
CHECK_INTERVAL=60  # Check every 60 seconds
ERROR_THRESHOLD=5   # Reset after 5 consecutive errors

error_count=0

################################################################################
# Logging function
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

################################################################################
# Check I2C bus status
################################################################################

check_i2c_status() {
    # Check if I2C bus 1 exists
    if [ ! -e "/dev/i2c-1" ]; then
        log "❌ I2C bus 1 not available"
        return 1
    fi
    
    # Check for recent I2C errors in dmesg (last 2 minutes)
    local recent_errors=$(dmesg -T | grep -i "i2c.*error\|i2c.*fail\|i2c.*timeout" | tail -10)
    if [ -n "$recent_errors" ]; then
        log "⚠️  Recent I2C errors detected:"
        echo "$recent_errors" | while read line; do
            log "   $line"
        done
        return 1
    fi
    
    return 0
}

################################################################################
# Attempt I2C recovery
################################################################################

attempt_recovery() {
    log "🔄 Attempting I2C recovery..."
    
    # Reload I2C modules
    modprobe -r i2c_bcm2835 2>/dev/null
    modprobe -r i2c_dev 2>/dev/null
    sleep 2
    modprobe i2c_bcm2835 2>/dev/null
    modprobe i2c_dev 2>/dev/null
    sleep 2
    
    # Reload FT6236 if needed
    if lsmod | grep -q "ft6236"; then
        modprobe -r ft6236 2>/dev/null
        sleep 1
        modprobe ft6236 2>/dev/null
        sleep 1
    fi
    
    log "✅ Recovery attempt completed"
}

################################################################################
# Main monitoring loop
################################################################################

main() {
    log "=== I2C MONITOR STARTED ==="
    log "Check interval: ${CHECK_INTERVAL} seconds"
    
    while true; do
        if check_i2c_status; then
            if [ $error_count -gt 0 ]; then
                log "✅ I2C bus recovered (error count reset)"
                error_count=0
            fi
        else
            error_count=$((error_count + 1))
            log "⚠️  I2C error detected (count: ${error_count}/${ERROR_THRESHOLD})"
            
            if [ $error_count -ge $ERROR_THRESHOLD ]; then
                log "❌ Error threshold reached, attempting recovery..."
                attempt_recovery
                error_count=0
            fi
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Run main function
main "$@"

