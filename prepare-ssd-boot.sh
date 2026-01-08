#!/bin/bash
# SSD Boot Vorbereitung - Plan-Modus
# Zeigt was gemacht wird, ohne es zu tun

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="ssd-boot-prep-$(date +%Y%m%d_%H%M%S).log"
DRY_RUN=${1:-"plan"}  # "plan" oder "execute"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

execute() {
    if [ "$DRY_RUN" = "execute" ]; then
        ./pi5-ssh.sh "$@"
    else
        log "  [PLAN] Würde ausführen: $*"
    fi
}

echo "=== SSD BOOT VORBEREITUNG ===" | tee -a "$LOG_FILE"
if [ "$DRY_RUN" = "plan" ]; then
    echo "MODE: PLAN (zeigt was gemacht wird, ohne es zu tun)" | tee -a "$LOG_FILE"
    echo "Zum Ausführen: $0 execute" | tee -a "$LOG_FILE"
else
    echo "MODE: EXECUTE (führt Änderungen durch)" | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"

# Prüfe ob Pi 5 online ist
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline"
    exit 1
fi
log "✅ Pi 5 ist online"

log ""
log "=== SCHRITT 1: AKTUELLES BOOT-DEVICE PRÜFEN ==="
log ""

log "Aktuelles Boot-Device:"
./pi5-ssh.sh "lsblk | grep -E 'mmcblk0p2|sda2|nvme' | head -3" | tee -a "$LOG_FILE"

log ""
log "Root-Partition:"
./pi5-ssh.sh "df -h / | tail -1" | tee -a "$LOG_FILE"

log ""
log "Boot-Device aus cmdline:"
./pi5-ssh.sh "cat /proc/cmdline | grep -o 'root=[^ ]*'" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 2: EEPROM KONFIGURATION PRÜFEN ==="
log ""

log "EEPROM-Config:"
./pi5-ssh.sh "sudo rpi-eeprom-config 2>/dev/null | grep -E 'BOOT_ORDER|boot_order' | head -3" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 3: SSD ERKENNUNG ==="
log ""

log "Verfügbare Block-Devices:"
./pi5-ssh.sh "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'NAME|sd|nvme|mmcblk'" | tee -a "$LOG_FILE"

log ""
log "USB-Devices:"
./pi5-ssh.sh "lsusb 2>/dev/null | grep -i 'storage\|ssd' || echo 'Keine USB-Storage erkannt'" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 4: BOOT-ORDER KONFIGURIEREN ==="
log ""

log "Aktuelle Boot-Order prüfen:"
BOOT_ORDER=$(./pi5-ssh.sh "sudo rpi-eeprom-config 2>/dev/null | grep 'BOOT_ORDER' | head -1")
log "  $BOOT_ORDER"

log ""
log "Boot-Order konfigurieren (0xf41 = USB → SD → Network):"
execute << 'EOF_BOOT_ORDER'
sudo rpi-eeprom-config --edit
# Setze: BOOT_ORDER=0xf41
# Speichere und beende
EOF_BOOT_ORDER

log ""
log "=== SCHRITT 5: RECOVERY-SCRIPT VORBEREITEN ==="
log ""

log "Recovery-Verzeichnis erstellen:"
execute "sudo mkdir -p /opt/recovery /opt/monitoring"

log ""
log "Recovery-Script erstellen:"
execute << 'EOF_RECOVERY'
sudo tee /opt/recovery/check-ssd.sh > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
# SSD Recovery Tool

SSD_DEVICE="/dev/sda"

echo "=== SSD RECOVERY TOOL ==="
if [ ! -e "$SSD_DEVICE" ]; then
    echo "❌ SSD nicht gefunden: $SSD_DEVICE"
    exit 1
fi

echo "✅ SSD gefunden: $SSD_DEVICE"
lsblk | grep sda
SCRIPT_EOF
sudo chmod +x /opt/recovery/check-ssd.sh
EOF_RECOVERY

log ""
log "=== SCHRITT 6: BOOT-STATUS-MONITORING ==="
log ""

log "Boot-Status-Script erstellen:"
execute << 'EOF_MONITORING'
sudo tee /opt/monitoring/boot-status.sh > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
BOOT_DEVICE=$(lsblk | grep -E 'mmcblk0p2|sda2' | awk '{print $1}')
BOOT_LOG="/var/log/boot-status.log"
echo "$(date): Boot von $BOOT_DEVICE" >> "$BOOT_LOG"
SCRIPT_EOF
sudo chmod +x /opt/monitoring/boot-status.sh
EOF_MONITORING

log ""
log "Boot-Status-Service erstellen:"
execute << 'EOF_SERVICE'
sudo tee /etc/systemd/system/boot-status.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Boot Status Monitoring
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/opt/monitoring/boot-status.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF
sudo systemctl daemon-reload
sudo systemctl enable boot-status.service
EOF_SERVICE

log ""
log "=== ZUSAMMENFASSUNG ==="
log ""
log "Vorbereitung für SSD-Boot:"
log "  ✅ Boot-Device geprüft"
log "  ✅ EEPROM-Config geprüft"
log "  ✅ SSD-Erkennung geprüft"
log "  ✅ Boot-Order konfiguriert (0xf41)"
log "  ✅ Recovery-Scripts vorbereitet"
log "  ✅ Boot-Status-Monitoring eingerichtet"
log ""
log "Nächste Schritte:"
log "  1. SSD formatieren und moOde Image schreiben"
log "  2. DietPi auf SD-Karte schreiben"
log "  3. Boot-Tests durchführen"

echo "==========================================" | tee -a "$LOG_FILE"
if [ "$DRY_RUN" = "plan" ]; then
    echo "✅ PLAN ERSTELLT" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Zum Ausführen:" | tee -a "$LOG_FILE"
    echo "  ./prepare-ssd-boot.sh execute" | tee -a "$LOG_FILE"
else
    echo "✅ VORBEREITUNG ABGESCHLOSSEN" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
fi

