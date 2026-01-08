#!/bin/bash
################################################################################
#
# AUTONOMOUS WORK SYSTEM
# 
# Arbeitet autonom weiter bis alles funktioniert
# - Prüft Pi-Verbindung (.143 und .162)
# - Wartet auf Pi-Verfügbarkeit
# - Führt Fixes aus wenn Pi online
# - Überwacht System kontinuierlich
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_FILE="$SCRIPT_DIR/autonomous-work.log"
# Prüfe alle möglichen IPs: .143 (ursprünglich), .161 (TARGET_IP), .162 (statische eth0), und DHCP-Bereich 160-180
# Bekannte IPs zuerst
PI_IPS=("192.168.178.143" "192.168.178.161" "192.168.178.162")
# Zusätzlich: DHCP-Bereich 160-180 für wlan0 (alle IPs im Bereich)
for ip in {160..180}; do
    PI_IPS+=("192.168.178.$ip")
done
PI_USER="andre"
PI_PASS="0815"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_pi_connection() {
    local ip=$1
    if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
        # Prüfe SSH
        if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            "$PI_USER@$ip" "echo 'connected'" >/dev/null 2>&1; then
            echo "$ip"
            return 0
        fi
    fi
    return 1
}

find_pi_ip() {
    log "🔍 Suche Pi..."
    for ip in "${PI_IPS[@]}"; do
        log "Prüfe $ip..."
        if check_pi_connection "$ip"; then
            log "✅ Pi gefunden: $ip"
            echo "$ip"
            return 0
        fi
    done
    return 1
}

apply_fixes() {
    local pi_ip=$1
    log "🔧 Wende Fixes an auf $pi_ip..."
    
    # Kopiere first-boot-setup falls nötig
    if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" \
        "[ ! -f /usr/local/bin/first-boot-setup.sh ]"; then
        log "📤 Kopiere first-boot-setup.sh..."
        sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=no \
            custom-components/scripts/first-boot-setup.sh \
            "$PI_USER@$pi_ip:/tmp/first-boot-setup.sh"
        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" \
            "sudo mv /tmp/first-boot-setup.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/first-boot-setup.sh"
    fi
    
    # Kopiere first-boot-setup.service falls nötig
    if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" \
        "[ ! -f /lib/systemd/system/first-boot-setup.service ]"; then
        log "📤 Kopiere first-boot-setup.service..."
        sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=no \
            custom-components/services/first-boot-setup.service \
            "$PI_USER@$pi_ip:/tmp/first-boot-setup.service"
        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" \
            "sudo mv /tmp/first-boot-setup.service /lib/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable first-boot-setup.service"
    fi
    
    # Prüfe ob first-boot-setup bereits gelaufen ist
    if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" \
        "[ ! -f /var/lib/first-boot-setup.done ]"; then
        log "🚀 Führe first-boot-setup aus..."
        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" \
            "sudo /usr/local/bin/first-boot-setup.sh" || log "⚠️  first-boot-setup fehlgeschlagen"
    else
        log "✅ first-boot-setup bereits ausgeführt"
    fi
    
    # Prüfe Services
    log "🔍 Prüfe Services..."
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" \
        "systemctl is-active localdisplay.service >/dev/null 2>&1" && \
        log "✅ localdisplay.service aktiv" || \
        log "⚠️  localdisplay.service nicht aktiv"
    
    # Prüfe Display
    log "🔍 Prüfe Display..."
    if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" \
        "export DISPLAY=:0 && xset q >/dev/null 2>&1"; then
        log "✅ X Server läuft"
    else
        log "⚠️  X Server läuft nicht"
    fi
    
    log "✅ Fixes angewendet"
}

main() {
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║  🚀 AUTONOMOUS WORK SYSTEM START                            ║"
    log "╚══════════════════════════════════════════════════════════════╝"
    log ""
    log "Pi IPs: ${PI_IPS[*]}"
    log "User: $PI_USER"
    log ""
    
    while true; do
        PI_IP=$(find_pi_ip)
        
        if [ -n "$PI_IP" ]; then
            log "✅ Pi erreichbar: $PI_IP"
            apply_fixes "$PI_IP"
            log "⏸️  Warte 60 Sekunden vor nächster Prüfung..."
            sleep 60
        else
            log "⏳ Pi nicht erreichbar, warte 30 Sekunden..."
            sleep 30
        fi
    done
}

# Prüfe ob sshpass installiert ist
if ! command -v sshpass >/dev/null 2>&1; then
    echo "❌ sshpass nicht installiert. Installiere..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install hudochenkov/sshpass/sshpass
        else
            echo "❌ Homebrew nicht installiert. Bitte installieren Sie sshpass manuell."
            exit 1
        fi
    else
        sudo apt-get install -y sshpass
    fi
fi

# Starte im Hintergrund
if [ "$1" != "--foreground" ]; then
    nohup "$0" --foreground > "$LOG_FILE" 2>&1 &
    echo "✅ Autonomes System gestartet (PID: $!)"
    echo "📋 Log: $LOG_FILE"
    echo "🛑 Stoppen mit: kill $!"
    exit 0
fi

# Hauptschleife
main

