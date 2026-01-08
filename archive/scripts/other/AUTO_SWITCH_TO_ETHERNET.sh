#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🔄 AUTOMATISCH AUF ETHERNET UMSCHALTEN                      ║
# ╚══════════════════════════════════════════════════════════════╝
# Prüft alle 10 Sekunden ob Ethernet konfiguriert ist und nutzt es dann

cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

LOG_FILE="ethernet-monitor-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "🔄 Ethernet-Monitor gestartet"
log "Prüft alle 10 Sekunden ob Ethernet konfiguriert ist..."

MAX_CHECKS=60  # 10 Minuten
CHECK_COUNT=0
ETHERNET_READY=false

while [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
    sleep 10
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    # Prüfe ob Ethernet DHCP hat
    ETH_IP=$(ifconfig en8 | grep "inet " | awk '{print $2}')
    ETH_CONFIG=$(networksetup -getinfo "AX88179A" 2>/dev/null | grep "Configuration:" | awk '{print $2}')
    DEFAULT_IF=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
    
    if [ "$ETH_CONFIG" = "DHCP" ] && [ -n "$ETH_IP" ] && [ "$ETH_IP" != "192.168.2.1" ]; then
        log "✅ Ethernet konfiguriert! IP: $ETH_IP"
        
        if [ "$DEFAULT_IF" = "en8" ]; then
            log "✅ Ethernet ist Standard-Route!"
            log "🚀 Build nutzt jetzt Ethernet (schneller)!"
            ETHERNET_READY=true
            break
        else
            log "⚠️  Ethernet konfiguriert, aber Wi-Fi noch Standard-Route"
            log "💡 Tipp: Wi-Fi temporär deaktivieren für Build"
        fi
    else
        if [ $((CHECK_COUNT % 6)) -eq 0 ]; then  # Alle Minute
            log "⏳ Warte auf Ethernet-Konfiguration... (Check $CHECK_COUNT/$MAX_CHECKS)"
        fi
    fi
done

if [ "$ETHERNET_READY" = true ]; then
    log ""
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║  ✅ ETHERNET BEREIT - BUILD NUTZT ETHERNET!                  ║"
    log "╚══════════════════════════════════════════════════════════════╝"
    log ""
    log "📊 Status:"
    log "   Ethernet IP: $ETH_IP"
    log "   Standard-Route: $DEFAULT_IF"
    log ""
    log "🚀 Build läuft jetzt schneller über Ethernet!"
else
    log ""
    log "⚠️  Ethernet nicht konfiguriert nach $MAX_CHECKS Checks"
    log "   Build nutzt weiterhin Wi-Fi"
fi

