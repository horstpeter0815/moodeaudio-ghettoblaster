#!/bin/bash
# Ghettoblaster - Aktiviert DSI und HDMI gleichzeitig
# Konfiguriert Multi-Display Setup

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="dual-display-setup-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== GHETTOBLASTER - DUAL DISPLAY SETUP ===" | tee -a "$LOG_FILE"

# Check if Pi 5 is online
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline. Bitte stellen Sie sicher, dass es läuft."
    exit 1
fi
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online!'" >/dev/null 2>&1; then
    log "❌ SSH-Verbindung zu Pi 5 fehlgeschlagen. Bitte überprüfen Sie das SSH-Setup."
    exit 1
fi
log "✅ Pi 5 ist online"

log ""
log "=== SCHRITT 1: BOOT-KONFIGURATION ANPASSEN ==="

# Aktuelle config.txt prüfen
log "Aktuelle config.txt:"
./pi5-ssh.sh "grep -E 'display_rotate|hdmi|dtoverlay.*dsi|dtoverlay.*vc4' /boot/firmware/config.txt" | tee -a "$LOG_FILE"

log ""
log "Aktualisiere config.txt für DSI + HDMI..."

./pi5-ssh.sh << 'EOF_CONFIG'
CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_FILE="/boot/firmware/config.txt.backup-$(date +%Y%m%d_%H%M%S)"

# Backup erstellen
sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "Backup erstellt: $BACKUP_FILE"

# KMS aktivieren (für Multi-Display)
if ! grep -q "dtoverlay=vc4-kms-v3d" "$CONFIG_FILE"; then
    echo "dtoverlay=vc4-kms-v3d" | sudo tee -a "$CONFIG_FILE"
    echo "✅ vc4-kms-v3d aktiviert"
else
    echo "✅ vc4-kms-v3d bereits aktiv"
fi

# DSI Overlay (WaveShare 7inch)
if ! grep -q "dtoverlay=vc4-kms-dsi-7inch" "$CONFIG_FILE"; then
    echo "dtoverlay=vc4-kms-dsi-7inch" | sudo tee -a "$CONFIG_FILE"
    echo "✅ DSI Overlay aktiviert"
else
    echo "✅ DSI Overlay bereits aktiv"
fi

# HDMI Auto-detect
if ! grep -q "^hdmi_group=0" "$CONFIG_FILE"; then
    # Entferne alte hdmi_group Einträge
    sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"
    echo "hdmi_group=0" | sudo tee -a "$CONFIG_FILE"
    echo "✅ HDMI Auto-detect aktiviert"
else
    echo "✅ HDMI Auto-detect bereits aktiv"
fi

# DSI Display Rotation beibehalten
if ! grep -q "^display_rotate=3" "$CONFIG_FILE"; then
    sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
    echo "display_rotate=3" | sudo tee -a "$CONFIG_FILE"
    echo "✅ DSI Rotation auf 3 gesetzt"
fi

echo ""
echo "Aktualisierte config.txt (relevant):"
grep -E 'display_rotate|hdmi|dtoverlay.*dsi|dtoverlay.*vc4' "$CONFIG_FILE"
EOF_CONFIG

log "✅ Boot-Konfiguration aktualisiert"

log ""
log "=== SCHRITT 2: X11 MULTI-DISPLAY SETUP ==="

# X11 Multi-Display Script erstellen
./pi5-ssh.sh << 'EOF_X11'
cat > /usr/local/bin/setup-multi-display.sh << 'SCRIPT_EOF'
#!/bin/bash
# Konfiguriert X11 für Multi-Display (DSI + HDMI)

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

log "=== MULTI-DISPLAY SETUP ==="

# Warte auf X Server
for i in {1..30}; do
    if xrandr --query >/dev/null 2>&1; then
        log "✅ X Server bereit"
        break
    fi
    if [ $i -eq 30 ]; then
        log "❌ X Server nicht bereit"
        exit 1
    fi
    sleep 1
done

# Prüfe verfügbare Displays
log "Verfügbare Displays:"
xrandr --query | grep -E " connected|disconnected" | tee -a /var/log/multi-display.log

# Finde DSI und HDMI Displays
DSI_DISPLAY=$(xrandr --query | grep -i "DSI" | grep " connected" | awk '{print $1}' | head -1)
HDMI_DISPLAY=$(xrandr --query | grep -i "HDMI" | grep " connected" | awk '{print $1}' | head -1)

log ""
log "DSI Display: $DSI_DISPLAY"
log "HDMI Display: $HDMI_DISPLAY"

if [ -n "$DSI_DISPLAY" ]; then
    # DSI konfigurieren (1280x400, Rotation)
    log "Konfiguriere DSI Display: $DSI_DISPLAY"
    
    # Prüfe verfügbare Modi
    DSI_MODES=$(xrandr --query | grep -A 10 "$DSI_DISPLAY" | grep -E "[0-9]+x[0-9]+")
    
    if echo "$DSI_MODES" | grep -q "1280x400"; then
        xrandr --output "$DSI_DISPLAY" --mode 1280x400 --rotate left 2>&1 | tee -a /var/log/multi-display.log
        log "✅ DSI auf 1280x400 (rotated) gesetzt"
    elif echo "$DSI_MODES" | grep -q "400x1280"; then
        xrandr --output "$DSI_DISPLAY" --mode 400x1280 --rotate left 2>&1 | tee -a /var/log/multi-display.log
        log "✅ DSI auf 400x1280 (rotated) gesetzt"
    else
        # Verwende ersten verfügbaren Modus
        FIRST_MODE=$(echo "$DSI_MODES" | head -1 | awk '{print $1}')
        xrandr --output "$DSI_DISPLAY" --mode "$FIRST_MODE" --rotate left 2>&1 | tee -a /var/log/multi-display.log
        log "✅ DSI auf $FIRST_MODE (rotated) gesetzt"
    fi
else
    log "⚠️  Kein DSI Display gefunden"
fi

if [ -n "$HDMI_DISPLAY" ]; then
    # HDMI konfigurieren (Auto-detect oder Full HD)
    log "Konfiguriere HDMI Display: $HDMI_DISPLAY"
    
    # Prüfe verfügbare Modi
    HDMI_MODES=$(xrandr --query | grep -A 10 "$HDMI_DISPLAY" | grep -E "[0-9]+x[0-9]+")
    
    # Versuche Full HD
    if echo "$HDMI_MODES" | grep -q "1920x1080"; then
        if [ -n "$DSI_DISPLAY" ]; then
            xrandr --output "$HDMI_DISPLAY" --mode 1920x1080 --right-of "$DSI_DISPLAY" 2>&1 | tee -a /var/log/multi-display.log
        else
            xrandr --output "$HDMI_DISPLAY" --mode 1920x1080 2>&1 | tee -a /var/log/multi-display.log
        fi
        log "✅ HDMI auf 1920x1080 gesetzt"
    else
        # Verwende ersten verfügbaren Modus
        FIRST_MODE=$(echo "$HDMI_MODES" | head -1 | awk '{print $1}')
        if [ -n "$DSI_DISPLAY" ]; then
            xrandr --output "$HDMI_DISPLAY" --mode "$FIRST_MODE" --right-of "$DSI_DISPLAY" 2>&1 | tee -a /var/log/multi-display.log
        else
            xrandr --output "$HDMI_DISPLAY" --mode "$FIRST_MODE" 2>&1 | tee -a /var/log/multi-display.log
        fi
        log "✅ HDMI auf $FIRST_MODE gesetzt"
    fi
else
    log "⚠️  Kein HDMI Display gefunden"
fi

log ""
log "=== DISPLAY-KONFIGURATION ABGESCHLOSSEN ==="
xrandr --query | grep -E " connected|disconnected" | tee -a /var/log/multi-display.log
SCRIPT_EOF

sudo chmod +x /usr/local/bin/setup-multi-display.sh
echo "✅ Multi-Display Script erstellt: /usr/local/bin/setup-multi-display.sh"
EOF_X11

log "✅ X11 Multi-Display Script erstellt"

log ""
log "=== SCHRITT 3: SYSTEMD SERVICE ERSTELLEN ==="

# Systemd Service für Multi-Display
./pi5-ssh.sh << 'EOF_SERVICE'
cat > /tmp/multi-display.service << 'SERVICE_EOF'
[Unit]
Description=Multi-Display Setup (DSI + HDMI)
After=localdisplay.service
Wants=localdisplay.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup-multi-display.sh
RemainAfterExit=yes
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority

[Install]
WantedBy=multi-user.target
SERVICE_EOF

sudo mv /tmp/multi-display.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable multi-display.service
echo "✅ Multi-Display Service erstellt und aktiviert"
EOF_SERVICE

log "✅ Systemd Service erstellt"

log ""
log "=== SCHRITT 4: VERIFIKATION ==="

log "Aktuelle Display-Konfiguration:"
./pi5-ssh.sh "cat /boot/firmware/config.txt | grep -E 'display_rotate|hdmi|dtoverlay.*dsi|dtoverlay.*vc4'" | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Boot-Konfiguration aktualisiert (DSI + HDMI)"
log "✅ X11 Multi-Display Script erstellt"
log "✅ Systemd Service erstellt und aktiviert"
log ""
log "Nächste Schritte:"
log "  1. Reboot durchführen"
log "  2. Beide Displays sollten erkannt werden"
log "  3. Multi-Display Service startet automatisch"
log ""
log "Nach Reboot prüfen:"
log "  xrandr --query"
log "  systemctl status multi-display.service"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ DUAL DISPLAY SETUP ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "⚠️  REBOOT ERFORDERLICH für Änderungen!" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

