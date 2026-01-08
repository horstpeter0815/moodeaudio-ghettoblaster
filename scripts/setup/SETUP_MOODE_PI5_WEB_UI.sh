#!/bin/bash
################################################################################
# SETUP MOODE PI5 VIA WEB UI (FirstBoot - SSH nicht verfügbar)
# 
# Versucht Config-Dateien über Web-UI oder direkt auf SD-Karte anzuwenden
################################################################################

# Don't exit on error - we want to try all methods
set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

PI5_IP="${1:-192.168.1.101}"
PI5_WEB="http://${PI5_IP}"

CONFIG_TXT="$PROJECT_ROOT/MOODE_PI5_WAVESHARE_HDMI_CONFIG.txt"
CMDLINE_TXT="$PROJECT_ROOT/sd_card_config/cmdline.txt"

################################################################################
# METHOD 1: Check if SD card is mounted
################################################################################

find_sd_card() {
    info "Suche nach gemounteter SD-Karte..."
    
    # Check common mount points on macOS
    MOUNT_POINTS=(
        "/Volumes/boot"
        "/Volumes/BOOT"
        "/Volumes/firmware"
        "/Volumes/FIRMWARE"
    )
    
    for mount in "${MOUNT_POINTS[@]}"; do
        if [ -d "$mount" ] && [ -f "$mount/config.txt" ]; then
            echo "$mount"
            return 0
        fi
    done
    
    # Check diskutil for mounted volumes
    while IFS= read -r line; do
        if echo "$line" | grep -qi "boot\|firmware"; then
            mount_point=$(echo "$line" | awk '{print $3}')
            if [ -d "$mount_point" ] && [ -f "$mount_point/config.txt" ]; then
                echo "$mount_point"
                return 0
            fi
        fi
    done < <(diskutil list | grep -i "boot\|firmware" || true)
    
    return 1
}

apply_to_sd_card() {
    local sd_mount="$1"
    
    if [ ! -d "$sd_mount" ]; then
        return 1
    fi
    
    log "SD-Karte gefunden: $sd_mount"
    
    # CRITICAL: Activate SSH first!
    info "Aktiviere SSH auf SD-Karte..."
    touch "$sd_mount/ssh" 2>/dev/null || true
    touch "$sd_mount/firmware/ssh" 2>/dev/null || true
    
    if [ -f "$sd_mount/ssh" ] || [ -f "$sd_mount/firmware/ssh" ]; then
        log "✅ SSH-Flag erstellt - SSH wird beim nächsten Boot aktiviert!"
    else
        warn "⚠️  Konnte SSH-Flag nicht erstellen"
    fi
    
    # Backup
    if [ -f "$sd_mount/config.txt" ]; then
        cp "$sd_mount/config.txt" "$sd_mount/config.txt.backup_$(date +%Y%m%d_%H%M%S)"
        info "Backup erstellt"
    fi
    
    # Apply config.txt
    if [ -f "$CONFIG_TXT" ]; then
        cp "$CONFIG_TXT" "$sd_mount/config.txt"
        log "✅ config.txt auf SD-Karte geschrieben"
    else
        warn "config.txt nicht gefunden: $CONFIG_TXT"
    fi
    
    # Apply cmdline.txt (if exists and we have the file)
    if [ -f "$CMDLINE_TXT" ] && [ -f "$sd_mount/cmdline.txt" ]; then
        # Preserve PARTUUID from existing cmdline.txt
        PARTUUID=$(grep -o 'root=PARTUUID=[^ ]*' "$sd_mount/cmdline.txt" | sed 's/root=PARTUUID=//' || echo "")
        
        if [ -n "$PARTUUID" ]; then
            # Read new cmdline and replace PARTUUID
            NEW_CMDLINE=$(cat "$CMDLINE_TXT")
            NEW_CMDLINE=$(echo "$NEW_CMDLINE" | sed "s/root=PARTUUID=[^ ]*/root=PARTUUID=${PARTUUID}/")
            echo "$NEW_CMDLINE" > "$sd_mount/cmdline.txt"
            log "✅ cmdline.txt auf SD-Karte geschrieben (PARTUUID erhalten)"
        else
            cp "$CMDLINE_TXT" "$sd_mount/cmdline.txt"
            warn "⚠️  PARTUUID nicht gefunden - cmdline.txt kopiert"
        fi
    fi
    
    # Sync
    sync
    log "✅ Config-Dateien auf SD-Karte angewendet!"
    log "✅ SSH wird beim nächsten Boot aktiviert sein!"
    return 0
}

################################################################################
# METHOD 2: Try Web UI API (if available)
################################################################################

check_web_ui() {
    info "Prüfe Web-UI: $PI5_WEB"
    
    if curl -s -f -o /dev/null --max-time 5 "$PI5_WEB" 2>/dev/null; then
        log "✅ Web-UI ist erreichbar"
        return 0
    else
        warn "Web-UI nicht erreichbar"
        return 1
    fi
}

try_web_api() {
    info "Versuche Config über Web-UI API..."
    
    # moOde doesn't have a direct API for config.txt, but we can try
    # to enable SSH via the web UI if there's a way
    
    warn "⚠️  moOde Web-UI hat keine direkte API für config.txt"
    warn "⚠️  Bitte manuell im Web-UI:"
    warn "   1. Gehe zu: $PI5_WEB"
    warn "   2. System → SSH → Enable SSH"
    warn "   3. Dann können wir per SSH die Config anwenden"
    
    return 1
}

################################################################################
# METHOD 3: Wait for SSH and apply
################################################################################

wait_for_ssh() {
    info "Warte auf SSH (nach FirstBoot)..."
    
    # Check if sshpass is available
    if ! command -v sshpass &> /dev/null; then
        warn "sshpass nicht installiert - kann SSH nicht prüfen"
        warn "Installiere mit: brew install hudochenkov/sshpass/sshpass"
        return 1
    fi
    
    local max_wait=300  # 5 minutes
    local waited=0
    
    while [ $waited -lt $max_wait ]; do
        if sshpass -p "moodeaudio" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "moode@${PI5_IP}" "echo 'SSH OK'" >/dev/null 2>&1; then
            log "✅ SSH ist bereit!"
            return 0
        fi
        
        # Try default moOde password
        if sshpass -p "moodeaudio" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "pi@${PI5_IP}" "echo 'SSH OK'" >/dev/null 2>&1; then
            log "✅ SSH ist bereit (User: pi)!"
            return 0
        fi
        
        echo -n "."
        sleep 5
        waited=$((waited + 5))
    done
    
    return 1
}

apply_via_ssh() {
    local user="${1:-moode}"
    local pass="${2:-moodeaudio}"
    
    log "Wende Config per SSH an (User: $user)..."
    
    if ! command -v sshpass &> /dev/null; then
        error "sshpass nicht gefunden. Installiere mit: brew install hudochenkov/sshpass/sshpass"
        return 1
    fi
    
    # Backup
    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@${PI5_IP}" \
        "sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true"
    
    # Apply config.txt
    if [ -f "$CONFIG_TXT" ]; then
        sshpass -p "$pass" scp -o StrictHostKeyChecking=no "$CONFIG_TXT" "$user@${PI5_IP}:/tmp/config.txt"
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@${PI5_IP}" \
            "sudo mount -o remount,rw /boot/firmware && sudo mv /tmp/config.txt /boot/firmware/config.txt && sudo chmod 644 /boot/firmware/config.txt"
        log "✅ config.txt angewendet"
    fi
    
    # Apply cmdline.txt
    if [ -f "$CMDLINE_TXT" ]; then
        sshpass -p "$pass" scp -o StrictHostKeyChecking=no "$CMDLINE_TXT" "$user@${PI5_IP}:/tmp/cmdline.txt"
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@${PI5_IP}" \
            "sudo mount -o remount,rw /boot/firmware && sudo mv /tmp/cmdline.txt /boot/firmware/cmdline.txt && sudo chmod 644 /boot/firmware/cmdline.txt"
        log "✅ cmdline.txt angewendet"
    fi
    
    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@${PI5_IP}" "sync"
    log "✅ Config-Dateien per SSH angewendet!"
    
    return 0
}

################################################################################
# MAIN
################################################################################

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  🌐 MOODE PI5 SETUP (Web-UI / FirstBoot)                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    info "Pi IP: $PI5_IP"
    echo ""
    
    # METHOD 1: Try SD card first (fastest if available)
    SD_MOUNT=$(find_sd_card)
    if [ -n "$SD_MOUNT" ]; then
        log "✅ SD-Karte gefunden!"
        if apply_to_sd_card "$SD_MOUNT"; then
            log "✅ Setup abgeschlossen! SD-Karte kann entfernt werden."
            echo ""
            info "Nächste Schritte:"
            info "  1. SD-Karte aus Mac entfernen"
            info "  2. SD-Karte in Pi einstecken"
            info "  3. Pi booten lassen"
            return 0
        fi
    else
        info "SD-Karte nicht gemountet (normal, wenn Pi bereits bootet)"
    fi
    
    echo ""
    
    # METHOD 2: Check Web UI
    if check_web_ui; then
        try_web_api
        echo ""
        info "Bitte SSH im Web-UI aktivieren:"
        info "  → $PI5_WEB"
        info "  → System → SSH → Enable"
        echo ""
    fi
    
    # METHOD 3: Wait for SSH
    info "Versuche SSH-Verbindung..."
    if wait_for_ssh; then
        apply_via_ssh "moode" "moodeaudio" || apply_via_ssh "pi" "raspberry"
        log "✅ Setup abgeschlossen!"
        return 0
    else
        error "SSH nicht verfügbar nach 5 Minuten"
        echo ""
        warn "Manuelle Schritte:"
        warn "  1. Öffne Web-UI: $PI5_WEB"
        warn "  2. Aktiviere SSH: System → SSH → Enable"
        warn "  3. Führe aus: ./SETUP_MOODE_PI5.sh $PI5_IP"
        return 1
    fi
}

main "$@"

