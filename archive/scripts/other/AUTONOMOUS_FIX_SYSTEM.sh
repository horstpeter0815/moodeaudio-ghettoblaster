#!/bin/bash
################################################################################
#
# AUTONOMOUS FIX SYSTEM
# 
# Automatically connects to Pi and fixes display service
# Runs continuously until successful
#
################################################################################

set -e

PI_IP="192.168.178.143"
PI_USER="andre"
PI_PASS="0815"
SCRIPT_NAME="FIX_DISPLAY_SERVICE.sh"
LOCAL_SCRIPT="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor/$SCRIPT_NAME"
LOG_FILE="/tmp/autonomous-fix-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== AUTONOMOUS FIX SYSTEM STARTED ==="
log "Target: $PI_USER@$PI_IP"
log "Script: $SCRIPT_NAME"

# Check if sshpass is available
if ! command -v sshpass &>/dev/null; then
    log "❌ sshpass not found, installing..."
    brew install hudochenkov/sshpass/sshpass 2>&1 | tee -a "$LOG_FILE" || {
        log "⚠️  Could not install sshpass, will try without it"
        USE_SSHPASS=false
    }
else
    USE_SSHPASS=true
    log "✅ sshpass available"
fi

# Function to test connection
test_connection() {
    if [ "$USE_SSHPASS" = true ]; then
        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            -o UserKnownHostsFile=/dev/null "$PI_USER@$PI_IP" "echo 'connected'" 2>&1
    else
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            -o UserKnownHostsFile=/dev/null "$PI_USER@$PI_IP" "echo 'connected'" 2>&1
    fi
}

# Function to copy script
copy_script() {
    log "Copying fix script to Pi..."
    if [ "$USE_SSHPASS" = true ]; then
        sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "$LOCAL_SCRIPT" "$PI_USER@$PI_IP:/tmp/" 2>&1 | tee -a "$LOG_FILE"
    else
        scp -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "$LOCAL_SCRIPT" "$PI_USER@$PI_IP:/tmp/" 2>&1 | tee -a "$LOG_FILE"
    fi
}

# Function to execute fix
execute_fix() {
    log "Executing fix script on Pi..."
    if [ "$USE_SSHPASS" = true ]; then
        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null "$PI_USER@$PI_IP" \
            "sudo bash /tmp/$SCRIPT_NAME" 2>&1 | tee -a "$LOG_FILE"
    else
        ssh -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null "$PI_USER@$PI_IP" \
            "sudo bash /tmp/$SCRIPT_NAME" 2>&1 | tee -a "$LOG_FILE"
    fi
}

# Function to verify fix
verify_fix() {
    log "Verifying fix..."
    if [ "$USE_SSHPASS" = true ]; then
        STATUS=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null "$PI_USER@$PI_IP" \
            "systemctl is-active localdisplay.service" 2>&1)
    else
        STATUS=$(ssh -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null "$PI_USER@$PI_IP" \
            "systemctl is-active localdisplay.service" 2>&1)
    fi
    
    if [ "$STATUS" = "active" ]; then
        log "✅ Service is ACTIVE - Fix successful!"
        return 0
    else
        log "⚠️  Service status: $STATUS"
        return 1
    fi
}

# Main loop
MAX_ATTEMPTS=120  # Try for 2 hours (every minute)
ATTEMPT=0
SUCCESS=false

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    log ""
    log "=== Attempt $ATTEMPT/$MAX_ATTEMPTS ==="
    
    # Test connection
    if test_connection >/dev/null 2>&1; then
        log "✅ Pi is reachable!"
        
        # Copy script
        if copy_script; then
            log "✅ Script copied"
            
            # Execute fix
            if execute_fix; then
                log "✅ Fix script executed"
                
                # Verify
                sleep 5
                if verify_fix; then
                    log "✅✅✅ FIX SUCCESSFUL - System is working!"
                    SUCCESS=true
                    break
                else
                    log "⚠️  Fix executed but service not active yet, checking logs..."
                    # Get logs
                    if [ "$USE_SSHPASS" = true ]; then
                        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no \
                            "$PI_USER@$PI_IP" \
                            "journalctl -u localdisplay.service -n 20 --no-pager" 2>&1 | tee -a "$LOG_FILE"
                    else
                        ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
                            "journalctl -u localdisplay.service -n 20 --no-pager" 2>&1 | tee -a "$LOG_FILE"
                    fi
                fi
            else
                log "❌ Fix script execution failed"
            fi
        else
            log "❌ Script copy failed"
        fi
    else
        log "⏳ Pi not reachable, waiting 60 seconds..."
    fi
    
    # Wait before next attempt (except if successful)
    if [ "$SUCCESS" = false ]; then
        sleep 60
    fi
done

if [ "$SUCCESS" = true ]; then
    log ""
    log "=== ✅ AUTONOMOUS FIX COMPLETE ==="
    log "System is working correctly!"
    log "Log file: $LOG_FILE"
    exit 0
else
    log ""
    log "=== ⚠️  AUTONOMOUS FIX TIMEOUT ==="
    log "Could not complete fix after $MAX_ATTEMPTS attempts"
    log "Check log file: $LOG_FILE"
    log "Pi may be offline or unreachable"
    exit 1
fi

