#!/bin/bash
# AUTONOMOUS_BUILD_TO_MOODE.sh
# Works continuously until Moode Audio is running
# NO INTERRUPTIONS - FULLY AUTONOMOUS

set -e

LOG_FILE="autonomous-build-to-moode-$(date +%Y%m%d_%H%M%S).log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== AUTONOMOUS BUILD TO MOODE START ==="
log "Working continuously until Moode Audio is running..."

# Wait for Build #32 to complete
log "Waiting for Build #32 to complete..."
LAST_IMAGE_COUNT=$(ls imgbuild/deploy/*.img 2>/dev/null | wc -l)

while true; do
    sleep 60
    
    # Check if new image appeared
    CURRENT_IMAGE_COUNT=$(ls imgbuild/deploy/*.img 2>/dev/null | wc -l)
    NEWEST_IMAGE=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1)
    
    if [ "$CURRENT_IMAGE_COUNT" -gt "$LAST_IMAGE_COUNT" ]; then
        log "✅ Neues Image erkannt: $(basename "$NEWEST_IMAGE")"
        
        # Wait for image to be complete
        sleep 30
        IMAGE_SIZE_1=$(stat -f%z "$NEWEST_IMAGE" 2>/dev/null || stat -c%s "$NEWEST_IMAGE" 2>/dev/null || echo "0")
        sleep 10
        IMAGE_SIZE_2=$(stat -f%z "$NEWEST_IMAGE" 2>/dev/null || stat -c%s "$NEWEST_IMAGE" 2>/dev/null || echo "0")
        
        if [ "$IMAGE_SIZE_1" -eq "$IMAGE_SIZE_2" ] && [ "$IMAGE_SIZE_1" -gt 1000000000 ]; then
            log "✅ Image vollständig"
            
            # Validate image
            log "=== VALIDIERE IMAGE ==="
            if bash VALIDATE_BUILD_IMAGE.sh >> "$LOG_FILE" 2>&1; then
                log "✅ Image-Validierung erfolgreich - Services sind im Image!"
                
                # Burn to SD card
                log "=== BRENNE IMAGE AUF SD-KARTE ==="
                if bash BURN_IMAGE_TO_SD.sh >> "$LOG_FILE" 2>&1; then
                    log "✅ Image auf SD-Karte gebrannt"
                    
                    # Wait for Pi to boot and check Moode Audio
                    log "=== WARTE AUF PI BOOT ==="
                    log "Pi sollte jetzt booten..."
                    sleep 30
                    
                    # Check if Pi is reachable
                    PI_IP="192.168.178.143"
                    for i in {1..60}; do
                        if ping -c 1 -W 1 "$PI_IP" >/dev/null 2>&1; then
                            log "✅ Pi ist erreichbar: $PI_IP"
                            
                            # Check Serial Console Debugger for boot information
                            if [ -f "serial-debugger.log" ]; then
                                RECENT_BOOT_ERRORS=$(tail -100 serial-debugger.log 2>/dev/null | grep -i "error\|fail\|boot\|ssh" | tail -5)
                                if [ -n "$RECENT_BOOT_ERRORS" ]; then
                                    log "📋 Serial Debugger zeigt: $RECENT_BOOT_ERRORS"
                                fi
                            fi
                            
                            # Check if SSH is available
                            if sshpass -p "0815" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 andre@"$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
                                log "✅ SSH verfügbar!"
                                
                                # Check Serial Console for SSH activation
                                if [ -f "serial-debugger.log" ]; then
                                    SSH_ACTIVATION=$(tail -200 serial-debugger.log 2>/dev/null | grep -i "ssh.*start\|ssh.*enable\|sshd.*start" | tail -3)
                                    if [ -n "$SSH_ACTIVATION" ]; then
                                        log "📋 Serial Debugger SSH-Aktivierung: $SSH_ACTIVATION"
                                    fi
                                fi
                                
                                # Check if Moode Audio is running
                                if sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@"$PI_IP" "systemctl is-active --quiet moode-startup && echo 'MOODE RUNNING'" >/dev/null 2>&1; then
                                    log "✅✅✅ MOODE AUDIO LÄUFT! ✅✅✅"
                                    log "=== AUTONOMOUS BUILD TO MOODE SUCCESS ==="
                                    exit 0
                                else
                                    log "⚠️  Moode Audio läuft noch nicht, warte..."
                                    # Check Serial Console for Moode startup
                                    if [ -f "serial-debugger.log" ]; then
                                        MOODE_STARTUP=$(tail -200 serial-debugger.log 2>/dev/null | grep -i "moode\|startup" | tail -3)
                                        if [ -n "$MOODE_STARTUP" ]; then
                                            log "📋 Serial Debugger Moode: $MOODE_STARTUP"
                                        fi
                                    fi
                                    sleep 30
                                fi
                            else
                                log "⚠️  SSH noch nicht verfügbar, warte..."
                                # Check Serial Console for SSH errors
                                if [ -f "serial-debugger.log" ]; then
                                    SSH_ERRORS=$(tail -100 serial-debugger.log 2>/dev/null | grep -i "ssh.*error\|ssh.*fail\|sshd.*error" | tail -3)
                                    if [ -n "$SSH_ERRORS" ]; then
                                        log "📋 Serial Debugger SSH-Fehler: $SSH_ERRORS"
                                    fi
                                fi
                                sleep 10
                            fi
                        else
                            log "⚠️  Pi noch nicht erreichbar, warte... (Versuch $i/60)"
                            sleep 10
                        fi
                    done
                    
                    log "⚠️  Pi nicht erreichbar nach 10 Minuten"
                else
                    log "❌ Image-Brennen fehlgeschlagen"
                fi
            else
                log "❌ Image-Validierung fehlgeschlagen - Services fehlen noch"
                log "→ Starte neuen Build..."
                # Start new build
                cd imgbuild && nohup bash build.sh > build-$(date +%Y%m%d_%H%M%S).log 2>&1 & cd ..
            fi
        fi
    fi
    
    # Check if build process is still running
    if ! ps aux | grep -E "build.sh|pi-gen" | grep -v grep >/dev/null 2>&1; then
        log "⚠️  Build-Prozess nicht mehr aktiv"
        if [ -n "$NEWEST_IMAGE" ] && [ -f "$NEWEST_IMAGE" ]; then
            log "Image gefunden, starte Validierung..."
            bash VALIDATE_BUILD_IMAGE.sh >> "$LOG_FILE" 2>&1
        fi
    fi
    
    LAST_IMAGE_COUNT=$CURRENT_IMAGE_COUNT
done

