#!/bin/bash
################################################################################
#
# MOODE PI5 QUICK SETUP
# 
# Wartet auf Pi Boot und wendet Config-Dateien an
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

################################################################################
# CONFIG FILES
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Pi 5 IP (anpassen falls nötig)
PI5_IP="${PI5_IP:-192.168.178.134}"
PI5_USER="andre"
PI5_PASS="0815"

# Config-Dateien (Waveshare HDMI + HiFiBerry AMP100)
CONFIG_TXT="$PROJECT_ROOT/MOODE_PI5_WAVESHARE_HDMI_CONFIG.txt"
# Fallback auf alte Config falls neue nicht existiert
[ ! -f "$CONFIG_TXT" ] && CONFIG_TXT="$PROJECT_ROOT/PI5_WORKING_CONFIG.txt"
CMDLINE_TXT="$PROJECT_ROOT/sd_card_config/cmdline.txt"

################################################################################
# WAIT FOR PI
################################################################################

wait_for_pi() {
    log "Warte auf Pi 5 Boot..."
    info "IP: $PI5_IP"
    info "User: $PI5_USER"
    info "Pass: $PI5_PASS"
    echo ""
    
    while true; do
        if ping -c 1 -W 2 "$PI5_IP" >/dev/null 2>&1; then
            log "✅ Pi 5 ist erreichbar!"
            sleep 3
            return 0
        fi
        echo -n "."
        sleep 2
    done
}

wait_for_ssh() {
    log "Warte auf SSH..."
    
    while true; do
        if sshpass -p "$PI5_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI5_USER@$PI5_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
            log "✅ SSH ist bereit!"
            return 0
        fi
        echo -n "."
        sleep 2
    done
}

################################################################################
# APPLY CONFIG
################################################################################

apply_config() {
    log "Wende Config-Dateien an..."
    
    # Prüfe ob sshpass verfügbar
    if ! command -v sshpass &> /dev/null; then
        error "sshpass nicht gefunden. Installiere mit: brew install hudochenkov/sshpass/sshpass"
        exit 1
    fi
    
    # Backup der originalen Config
    info "Erstelle Backup der originalen Config..."
    sshpass -p "$PI5_PASS" ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" \
        "sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup && \
         sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup" 2>/dev/null || true
    
    # Kopiere Config-Dateien
    if [ -f "$CONFIG_TXT" ]; then
        info "Kopiere config.txt..."
        sshpass -p "$PI5_PASS" scp -o StrictHostKeyChecking=no "$CONFIG_TXT" "$PI5_USER@$PI5_IP:/tmp/config.txt"
        sshpass -p "$PI5_PASS" ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" \
            "sudo mv /tmp/config.txt /boot/firmware/config.txt && sudo chown root:root /boot/firmware/config.txt"
        log "✅ config.txt angewendet"
    else
        warn "config.txt nicht gefunden: $CONFIG_TXT"
    fi
    
    if [ -f "$CMDLINE_TXT" ]; then
        info "Kopiere cmdline.txt..."
        sshpass -p "$PI5_PASS" scp -o StrictHostKeyChecking=no "$CMDLINE_TXT" "$PI5_USER@$PI5_IP:/tmp/cmdline.txt"
        sshpass -p "$PI5_PASS" ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" \
            "sudo mv /tmp/cmdline.txt /boot/firmware/cmdline.txt && sudo chown root:root /boot/firmware/cmdline.txt"
        log "✅ cmdline.txt angewendet"
    else
        warn "cmdline.txt nicht gefunden: $CMDLINE_TXT"
    fi
    
    log "✅ Config-Dateien angewendet!"
    warn "⚠️  Reboot erforderlich!"
    echo ""
    read -p "Jetzt rebooten? (y/N): " reboot_confirm
    
    if [ "$reboot_confirm" = "y" ]; then
        log "Reboote Pi 5..."
        sshpass -p "$PI5_PASS" ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" "sudo reboot"
        log "✅ Reboot gestartet. Warte auf Neustart..."
        sleep 10
        wait_for_pi
        wait_for_ssh
        log "✅ Pi 5 ist wieder online!"
    else
        info "Reboot manuell mit: ssh $PI5_USER@$PI5_IP 'sudo reboot'"
    fi
}

################################################################################
# MAIN
################################################################################

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  🚀 MOODE PI5 QUICK SETUP                                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # IP überschreiben falls als Argument gegeben
    if [ -n "$1" ]; then
        PI5_IP="$1"
        info "IP überschrieben: $PI5_IP"
    fi
    
    # Warte auf Pi
    wait_for_pi
    wait_for_ssh
    
    # Wende Config an
    apply_config
    
    log "✅ Setup abgeschlossen!"
}

main "$@"

