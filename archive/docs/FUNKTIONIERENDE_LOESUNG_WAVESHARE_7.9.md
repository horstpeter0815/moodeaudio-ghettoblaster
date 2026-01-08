# Funktionierende Lösung: Waveshare 7.9" HDMI Display auf Raspberry Pi 5 mit Moode Audio

**Datum:** 30. November 2025  
**Hardware:** Raspberry Pi 5, Waveshare 7.9" HDMI LCD (1280x400)  
**Software:** Moode Audio 10.0.0, Raspberry Pi OS 13.2 (Trixie)

---

## ✅ Problem gelöst

Nach vielen Stunden der Fehlersuche wurde die **ursächliche Lösung** gefunden:

**Das Hauptproblem war:** Der Framebuffer wurde beim Boot im Portrait-Modus (400x1280) initialisiert, obwohl der Display-Mode auf 1280x400 gesetzt wurde. Chromium konnte daher nicht richtig rendern.

**Die Lösung:** Der `video=` Parameter in `cmdline.txt` setzt den Framebuffer beim Boot direkt auf 1280x400 (Landscape), **OHNE** `rotate=90`.

---

## 📋 Vollständige Konfiguration

### 1. `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=e77cf027-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE consoleblank=0 video=HDMI-A-2:1280x400M@60
```

**WICHTIG:**
- `video=HDMI-A-2:1280x400M@60` - Setzt Framebuffer beim Boot auf 1280x400 (Landscape)
- **KEIN** `rotate=90` - Rotation wird von X11/xrandr übernommen
- `HDMI-A-2` für Pi 5 (Pi 4 verwendet `HDMI-A-1`)

### 2. `/boot/firmware/config.txt` (HDMI-Abschnitt)

```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
hdmi_force_hotplug=1
hdmi_drive=2
display_rotate=0
```

**WICHTIG:**
- `hdmi_cvt 1280 400 60 6 0 0 0` - Definiert Custom-Mode (1280x400 @ 60Hz)
- `hdmi_mode=87` - Verwendet Custom-Mode
- `hdmi_group=2` - DMT (Display Monitor Timings)
- `display_rotate=0` - Keine Rotation auf Kernel-Ebene

### 3. `/home/andre/.xinitrc` (Chromium-Start-Abschnitt)

```bash
# WARTE BIS X SERVER VOLLSTÄNDIG BEREIT IST
echo "Warte auf X Server..."
for i in {1..30}; do
    if xset q >/dev/null 2>&1; then
        echo "✅ X Server bereit nach $i Sekunden"
        break
    fi
    sleep 1
done

# Zusätzliche Wartezeit für Display-Initialisierung
sleep 3

# CUSTOM: Füge 1280x400 Mode hinzu für Waveshare Display
DISPLAY=:0
xrandr --newmode "1280x400_60.00"   25.20  1280 1328 1456 1632  400 401 404 420 -hsync +vsync 2>/dev/null
xrandr --addmode HDMI-2 "1280x400_60.00" 2>/dev/null
xrandr --output HDMI-2 --mode "1280x400_60.00" 2>/dev/null || xrandr --output HDMI-2 --auto 2>/dev/null

# Warte auf Display-Mode
sleep 2

# Setze SCREEN_RES explizit auf 1280,400 falls falsch
SCREEN_RES="1280,400"

# Launch WebUI
if [ $WEBUI_SHOW = "1" ]; then
    # Clear browser cache
    $(/var/www/util/sysutil.sh clearbrcache)
    # Launch chromium browser - OHNE exec, im Hintergrund
    echo "Starte Chromium mit SCREEN_RES=$SCREEN_RES..."
    chromium \
        --no-sandbox \
        http://localhost/ \
        --window-size="$SCREEN_RES" \
        --window-position="0,0" \
        --enable-features="OverlayScrollbar" \
        --no-first-run \
        --disable-infobars \
        --disable-session-crashed-bubble \
        --disable-gpu \
        --disable-software-rasterizer \
        --disable-dev-shm-usage \
        --kiosk &
    
    # Warte auf Chromium
    sleep 10
    
    # Keep xinit alive
    while true; do
        sleep 60
    done
fi
```

**WICHTIG:**
- **`--no-sandbox`** - **KRITISCH!** Chromium benötigt diesen Parameter auf Pi 5, sonst wird es "Killed"
- **KEIN** `--app="http://localhost/"` - Verwendet normale URL `http://localhost/`
- **KEIN** `exec chromium` - Chromium läuft im Hintergrund, xinit bleibt aktiv
- Explizite Wartezeit auf X Server
- Display-Mode wird explizit gesetzt
- `SCREEN_RES` wird auf `1280,400` gesetzt

---

## 🔧 Permanente Lösung

### Systemd-Service für .xinitrc-Restore

**Datei:** `/etc/systemd/system/waveshare-display-fix.service`

```ini
[Unit]
Description=Restore Waveshare Display .xinitrc
After=localdisplay.service
Requires=localdisplay.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restore-waveshare-xinitrc.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**Script:** `/usr/local/bin/restore-waveshare-xinitrc.sh`

```bash
#!/bin/bash
# Restore Waveshare Display .xinitrc from template

XINITRC_PATH="/home/andre/.xinitrc"
TEMPLATE_PATH="/usr/local/lib/moode-display/xinitrc.waveshare"

# Ensure the template exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Error: Template file not found at $TEMPLATE_PATH"
    exit 1
fi

# Check if the current .xinitrc contains the custom mode
if ! grep -q "xrandr --newmode \"1280x400_60.00\"" "$XINITRC_PATH"; then
    echo "Restoring .xinitrc from template..."
    cp "$TEMPLATE_PATH" "$XINITRC_PATH"
    chmod +x "$XINITRC_PATH"
else
    echo ".xinitrc already contains custom mode, no restore needed."
fi
```

**Template:** `/usr/local/lib/moode-display/xinitrc.waveshare`

Die vollständige `.xinitrc` wird als Template gespeichert und nach jedem Reboot wiederhergestellt.

---

## ✅ Erwartetes Verhalten

1. **Boot:** Framebuffer wird auf 1280x400 (Landscape) initialisiert
2. **X Server:** Startet und wartet auf vollständige Initialisierung
3. **Display-Mode:** Wird auf 1280x400_60.00 gesetzt
4. **Chromium:** Startet im Kiosk-Mode mit 1280x400 Fenster
5. **Display:** Zeigt Moode WebUI korrekt in Landscape

---

## 🔍 Diagnose-Befehle

```bash
# Framebuffer prüfen
fbset -s

# Display-Mode prüfen
export DISPLAY=:0
xrandr --query | grep -A3 "HDMI-2 connected"

# Chromium-Fenster prüfen
xwininfo -root -tree | grep -i chromium

# Service-Status prüfen
systemctl status localdisplay.service
```

---

## 📝 Wichtige Erkenntnisse

1. **Framebuffer-Initialisierung:** Der `video=` Parameter in `cmdline.txt` ist **kritisch** für die korrekte Framebuffer-Initialisierung beim Boot.

2. **Keine doppelte Rotation:** Rotation wird nur von X11/xrandr übernommen, nicht vom Kernel (`video=` Parameter ohne `rotate=90`).

3. **Chromium-Parameter:** 
   - **`--no-sandbox` ist KRITISCH** - Ohne diesen Parameter wird Chromium "Killed" auf Pi 5
   - `--app` Parameter kann Probleme verursachen. Normale URL `http://localhost/` funktioniert besser

4. **xinit am Leben halten:** Chromium muss **ohne** `exec` gestartet werden, damit xinit aktiv bleibt.

5. **Wartezeiten:** Explizite Wartezeiten auf X Server und Display-Initialisierung sind notwendig.

---

## 🎯 Status

**✅ FUNKTIONIERT:**
- Framebuffer: 1280x400 (Landscape)
- X Server: läuft
- Display-Mode: 1280x400_60.00
- Chromium: erstellt Hauptfenster
- Service: aktiv und persistent

**⚠️  Getestet nach:**
- Einem Reboot ✅
- Service-Neustart ✅

**🔜 Noch zu testen:**
- Mehrere Reboots (3+)
- Langzeit-Stabilität

---

**Erstellt:** 30. November 2025, 05:10 Uhr  
**Status:** ✅ FUNKTIONIERT

