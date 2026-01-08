#!/bin/bash
################################################################################
#
# MONITOR BOOT NOW - Überwacht Boot-Prozess und prüft alle Fixes
#
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[BOOT-MONITOR]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 BOOT-MONITORING - Warte auf Pi                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# IP-Adressen zum Testen
# ⚠️ WICHTIG: 192.168.1.101 ist der FREMDE WLAN-ROUTER, NICHT der Pi!
# Der Benutzer hat das 100+ MAL gesagt - NIEMALS .101 verwenden!
IP_ADDRESSES=("192.168.10.2" "192.168.1.100" "moodepi5.local" "GhettoBlaster.local")

ATTEMPTS=0
MAX_ATTEMPTS=120  # 20 Minuten (10 Sekunden pro Versuch)
PI_ONLINE=false
SSH_WORKS=false

log "Starte Boot-Monitoring..."
log "Prüfe alle 10 Sekunden..."
echo ""

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    
    echo "[$(date +%H:%M:%S)] Versuch $ATTEMPTS/$MAX_ATTEMPTS..."
    
    # Teste alle IP-Adressen
    for IP in "${IP_ADDRESSES[@]}"; do
        # ⚠️ KRITISCH: .101 ist der fremde Router, NICHT der Pi!
        if echo "$IP" | grep -q "\.101$"; then
            warn "⚠️  Überspringe $IP (fremder WLAN-Router, NICHT der Pi!)"
            continue
        fi
        
        # Ping-Test
        if ping -c 1 -W 1 "$IP" >/dev/null 2>&1; then
            info "✅ IP erreichbar: $IP"
            PI_ONLINE=true
            
            # SSH-Test
            if timeout 3 ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null andre@"$IP" "echo 'SSH OK'" >/dev/null 2>&1; then
                info "✅ SSH funktioniert auf $IP!"
                SSH_WORKS=true
                
                echo ""
                echo "╔══════════════════════════════════════════════════════════════╗"
                echo "║  ✅ PI IST ONLINE UND SSH FUNKTIONIERT!                    ║"
                echo "╚══════════════════════════════════════════════════════════════╝"
                echo ""
                
                # Prüfe config.txt (wichtigste Prüfung!)
                log "Prüfe config.txt auf Pi..."
                CONFIG_CHECK=$(ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no andre@"$IP" "head -2 /boot/firmware/config.txt" 2>/dev/null)
                
                if echo "$CONFIG_CHECK" | grep -q "# This file is managed by moOde"; then
                    LINE1=$(echo "$CONFIG_CHECK" | head -1)
                    LINE2=$(echo "$CONFIG_CHECK" | sed -n '2p')
                    
                    if [ -z "$LINE1" ] || [ "$LINE1" = "" ]; then
                        log "✅ Zeile 1 ist leer (korrekt)"
                    else
                        warn "⚠️  Zeile 1 ist nicht leer: '$LINE1'"
                    fi
                    
                    if [ "$LINE2" = "# This file is managed by moOde" ]; then
                        log "✅ Zeile 2 hat Main Header (config.txt wurde NICHT überschrieben!)"
                    else
                        error "❌ Zeile 2 hat NICHT den Main Header!"
                        error "   → config.txt wurde möglicherweise überschrieben!"
                    fi
                else
                    error "❌ Main Header nicht gefunden!"
                    error "   → config.txt wurde möglicherweise überschrieben!"
                fi
                
                # Prüfe display_rotate
                log "Prüfe display_rotate..."
                DISPLAY_ROTATE=$(ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no andre@"$IP" "grep -A 10 '\[pi5\]' /boot/firmware/config.txt | grep 'display_rotate=' | head -1" 2>/dev/null)
                if echo "$DISPLAY_ROTATE" | grep -q "display_rotate=2"; then
                    log "✅ display_rotate=2 gefunden in [pi5] Section"
                else
                    warn "⚠️  display_rotate=2 nicht gefunden"
                fi
                
                # Prüfe cmdline.txt (Forum-Lösung)
                log "Prüfe cmdline.txt (Forum-Lösung)..."
                CMDLINE=$(ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no andre@"$IP" "cat /boot/firmware/cmdline.txt" 2>/dev/null)
                if echo "$CMDLINE" | grep -q "video=HDMI-A-2:400x1280M@60,rotate=90"; then
                    log "✅ Forum-Lösung video= Parameter gefunden"
                else
                    warn "⚠️  Forum-Lösung video= Parameter nicht gefunden"
                fi
                
                # Prüfe IP-Adresse
                log "Prüfe IP-Adresse..."
                ACTUAL_IP=$(ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no andre@"$IP" "ip addr show eth0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" 2>/dev/null)
                if [ -n "$ACTUAL_IP" ]; then
                    if [ "$ACTUAL_IP" = "192.168.10.2" ]; then
                        log "✅ IP-Adresse korrekt: $ACTUAL_IP (Direct LAN)"
                    elif [ "$ACTUAL_IP" != "127.0.0.1" ] && [ "$ACTUAL_IP" != "127.0.1.1" ]; then
                        info "ℹ️  IP-Adresse: $ACTUAL_IP (nicht 192.168.10.2, aber auch nicht localhost)"
                    else
                        error "❌ IP-Adresse ist localhost: $ACTUAL_IP"
                    fi
                fi
                
                echo ""
                echo "📋 VERBINDUNG:"
                echo "   SSH: ssh andre@$IP"
                echo "   Password: 0815"
                echo "   Web-UI: http://$IP"
                echo ""
                
                exit 0
            else
                info "⏳ SSH noch nicht bereit auf $IP..."
            fi
            
            # Web-UI Test
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://$IP" 2>/dev/null)
            if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
                info "✅ Web-UI erreichbar (HTTP $HTTP_CODE)"
            fi
            
            break
        fi
    done
    
    if [ "$PI_ONLINE" = false ]; then
        echo "⏳ Pi noch nicht erreichbar..."
    fi
    
    echo ""
    sleep 10
done

if [ "$PI_ONLINE" = false ]; then
    error "❌ Timeout: Pi konnte nicht erreicht werden"
    error "   Prüfe:"
    error "   - Ist Pi eingeschaltet?"
    error "   - Ist Netzwerk-Kabel verbunden?"
    error "   - Ist Mac Ethernet konfiguriert (192.168.10.1)?"
    exit 1
fi

if [ "$SSH_WORKS" = false ]; then
    error "❌ Pi ist online, aber SSH funktioniert nicht"
    error "   Prüfe:"
    error "   - Ist SSH-Flag auf SD-Karte vorhanden?"
    error "   - Warte noch etwas (SSH startet manchmal später)"
    exit 1
fi

