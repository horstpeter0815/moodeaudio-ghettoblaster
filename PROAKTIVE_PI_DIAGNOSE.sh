#!/bin/bash
################################################################################
#
# PROAKTIVE PI-DIAGNOSE
# 
# Analysiert WARUM der Pi nicht erreichbar ist und bietet Lösungen
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_FILE="$SCRIPT_DIR/pi-diagnose.log"
PI_IPS=("192.168.178.143" "192.168.178.161" "192.168.178.162")

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== PROAKTIVE PI-DIAGNOSE START ==="

# 1. NETZWERK-PRÜFUNG
log "1. Netzwerk-Prüfung..."
ROUTER_REACHABLE=false
if ping -c 1 -W 1 192.168.178.1 >/dev/null 2>&1; then
    ROUTER_REACHABLE=true
    log "✅ Router erreichbar"
else
    log "❌ Router NICHT erreichbar - Netzwerk-Problem!"
fi

# 2. PI-IP-PRÜFUNG
log "2. Pi-IP-Prüfung..."
PI_FOUND=false
for ip in "${PI_IPS[@]}"; do
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        log "✅ Pi erreichbar auf $ip"
        PI_FOUND=true
        break
    else
        log "❌ Pi NICHT erreichbar auf $ip"
    fi
done

# 3. NETZWERK-SCAN
log "3. Netzwerk-Scan..."
if command -v nmap >/dev/null 2>&1; then
    log "Scanne Netzwerk nach aktiven Geräten..."
    nmap -sn 192.168.178.0/24 2>/dev/null | grep -E "192.168.178" | head -10 >> "$LOG_FILE" 2>&1 || true
else
    log "⚠️  nmap nicht verfügbar, überspringe Scan"
fi

# 4. ANALYSE DER MÖGLICHEN PROBLEME
log ""
log "=== PROBLEM-ANALYSE ==="

if [ "$ROUTER_REACHABLE" = false ]; then
    log "❌ PROBLEM: Router nicht erreichbar"
    log "   → Mac ist nicht im richtigen Netzwerk"
    log "   → Netzwerk-Kabel/Adapter defekt"
    log "   → Router-Problem"
elif [ "$PI_FOUND" = false ]; then
    log "❌ PROBLEM: Pi nicht erreichbar"
    log ""
    log "Mögliche Ursachen:"
    log "1. Pi bootet nicht (SD-Karte defekt/falsch gebrannt)"
    log "2. Netzwerk-Konfiguration falsch im Image"
    log "3. Pi hat andere IP (DHCP)"
    log "4. Hardware-Problem (Strom, Kabel)"
    log "5. Image bootet nicht richtig (first-boot fehlt)"
    log ""
    log "LÖSUNGEN:"
    log ""
    log "A) PHYSISCH PRÜFEN:"
    log "   - Ist der Pi eingeschaltet? (LED leuchtet?)"
    log "   - Netzwerk-Kabel angeschlossen?"
    log "   - Stromversorgung OK?"
    log ""
    log "B) SD-KARTE PRÜFEN:"
    log "   - Image korrekt gebrannt?"
    log "   - SD-Karte defekt?"
    log "   - Boot-Partition vorhanden?"
    log ""
    log "C) IMAGE PRÜFEN:"
    log "   - Wurde das Image mit first-boot-setup gebaut?"
    log "   - Netzwerk-Konfiguration korrekt?"
    log "   - Services aktiviert?"
    log ""
    log "D) NETZWERK-PRÜFUNG:"
    log "   - Pi könnte andere IP haben (DHCP)"
    log "   - Router zeigt verbundene Geräte?"
    log ""
    log "E) SERIAL CONSOLE:"
    log "   - Direkter Zugriff über Serial/USB"
    log "   - Boot-Logs prüfen"
else
    log "✅ Pi ist erreichbar!"
fi

log ""
log "=== NÄCHSTE SCHRITTE ==="
log ""
log "1. Erstelle Boot-Validierungs-Script"
log "2. Erstelle Netzwerk-Fix-Script"
log "3. Erstelle Image-Prüfungs-Script"
log "4. Erstelle Serial-Console-Anleitung"

log "=== PROAKTIVE PI-DIAGNOSE END ==="

