# ✅ FUNKTIONIERENDE LÖSUNG - MOODE AUDIO PI 5 MIT WAVESHARE 7.9" DISPLAY

**Datum:** 30. November 2025  
**Status:** ✅ **FUNKTIONIERT PERFEKT!**  
**WebUI:** http://192.168.178.178/per-config.php#restart-local-display  
**Hardware:** Raspberry Pi 5, Waveshare 7.9" HDMI LCD (1280x400)

---

## 🎉 ERFOLG!

**Das Display funktioniert jetzt perfekt!**  
**Die Moode WebUI ist erreichbar und funktioniert!**

---

## 📋 VOLLSTÄNDIGE KONFIGURATION

### 1. `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=e77cf027-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE consoleblank=0 video=HDMI-A-2:400x1280M@60,rotate=90
```

**WICHTIG:**
- `video=HDMI-A-2:400x1280M@60,rotate=90` - Display startet Portrait (400x1280), wird dann rotiert
- `HDMI-A-2` - Korrekter HDMI Port für Pi 5

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
- `hdmi_cvt 1280 400 60 6 0 0 0` - Custom-Mode für 1280x400 @ 60Hz
- `hdmi_mode=87` - Verwendet Custom-Mode
- `hdmi_group=2` - DMT (Display Monitor Timings)

### 3. `/home/andre/.xinitrc` (Wichtige Abschnitte)

```bash
# WARTE BIS X SERVER VOLLSTÄNDIG BEREIT IST
for i in {1..30}; do
    if xset q >/dev/null 2>&1; then
        echo "✅ X Server bereit nach $i Sekunden"
        break
    fi
    sleep 1
done
sleep 3

# CUSTOM: Füge 1280x400 Mode hinzu
DISPLAY=:0
xrandr --newmode "1280x400_60.00"   25.20  1280 1328 1456 1632  400 401 404 420 -hsync +vsync 2>/dev/null
xrandr --addmode HDMI-2 "1280x400_60.00" 2>/dev/null

# WICHTIG: Rotation IMMER setzen (Display startet Portrait, wird zu Landscape)
if [ $DSI_SCN_TYPE = 'none' ]; then
    DISPLAY=:0 xrandr --output HDMI-2 --rotate left
    if [ $HDMI_SCN_ORIENT = "portrait" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
    fi
fi

# Launch chromium browser
chromium --no-sandbox \
    --app="http://localhost/" \
    --window-size="1280,400" \
    --window-position="0,0" \
    --enable-features="OverlayScrollbar" \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-gpu \
    --disable-software-rasterizer \
    --kiosk &

# Invertiere Touchscreen-Achsen
export DISPLAY=:0
TOUCH_ID=$(xinput list 2>/dev/null | grep -iE "touch|waveshare|ft5x06" | grep -o "id=[0-9]*" | head -1 | cut -d= -f2)
if [ ! -z "$TOUCH_ID" ]; then
    xinput set-prop $TOUCH_ID "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
    echo "✅ Touchscreen-Achsen invertiert (ID: $TOUCH_ID)"
fi

# Keep xinit alive
while true; do
    sleep 60
done
```

**WICHTIG:**
- **`--no-sandbox`** - KRITISCH! Chromium benötigt diesen Parameter auf Pi 5
- **`xrandr --output HDMI-2 --rotate left`** - Rotation wird IMMER gesetzt
- **`--window-size="1280,400"`** - Explizit auf Landscape gesetzt (nicht `$SCREEN_RES`)
- **Touchscreen-Inversion** - Beide Achsen werden invertiert

---

## 🔑 KRITISCHE PUNKTE

1. **cmdline.txt:** `video=HDMI-A-2:400x1280M@60,rotate=90` - Display startet Portrait, wird rotiert
2. **xinitrc:** `xrandr --output HDMI-2 --rotate left` - Rotation wird IMMER gesetzt
3. **Chromium:** `--no-sandbox` - Ohne diesen Parameter wird Chromium "Killed"
4. **Chromium:** `--window-size="1280,400"` - Explizit setzen, nicht `$SCREEN_RES` verwenden
5. **Touchscreen:** Transformation Matrix `-1 0 1, 0 -1 1, 0 0 1` - Beide Achsen invertiert

---

## ✅ ERFOLGS-KRITERIEN

- ✅ Display zeigt vollständiges Bild (keine schwarzen Bereiche)
- ✅ Landscape (1280x400) korrekt
- ✅ Chromium Window-Size = xrandr Resolution (konsistent)
- ✅ Rotation persistent (wird bei jedem X11 Start gesetzt)
- ✅ Chromium läuft mit Renderer-Prozessen
- ✅ Moode WebUI erreichbar und funktioniert
- ✅ Touchscreen-Achsen invertiert

---

## 🔧 BACKUP & RESTORE

**Backup-Verzeichnis auf Pi:**
```
/home/andre/WORKING_CONFIG_BACKUP_[TIMESTAMP]/
```

**Enthält:**
- `cmdline.txt` - Boot-Parameter
- `config.txt` - Hardware-Konfiguration
- `xinitrc` - X11 Start-Script
- `xinitrc.waveshare.template` - Template für automatische Wiederherstellung
- `CONFIG_REPORT.txt` - Vollständiger Konfigurations-Report
- `SYSTEM_STATUS.txt` - System-Status zum Zeitpunkt des Backups
- `RESTORE_CONFIG.sh` - Script zum Wiederherstellen der Konfiguration

**Wiederherstellen:**
```bash
cd /home/andre/WORKING_CONFIG_BACKUP_[TIMESTAMP]/
sudo ./RESTORE_CONFIG.sh
sudo reboot
```

---

## 📝 WICHTIGE ERKENNTNISSE

1. **Warum Portrait zuerst?** Das Display funktioniert nur, wenn es mit Portrait (400x1280) startet. Die Rotation zu Landscape (1280x400) erfolgt dann über xrandr.

2. **Warum explizite Window-Size?** `$SCREEN_RES` wird aus dem Framebuffer gelesen, der Portrait (400,1280) ist. Chromium braucht aber Landscape (1280,400).

3. **Warum --no-sandbox?** Chromium wird ohne diesen Parameter "Killed" auf Pi 5. Das ist ein bekanntes Problem mit Chromium auf Raspberry Pi.

4. **Warum doppelte Rotation?** Die erste Rotation in xinitrc setzt immer Landscape, auch wenn Moode auf landscape steht. Das ist notwendig, weil das Display mit Portrait startet.

---

## 🎯 STATUS

**✅ FUNKTIONIERT PERFEKT!**

- ✅ Vollständiges Bild sichtbar
- ✅ Landscape (1280x400)
- ✅ Keine schwarzen Bereiche
- ✅ Konsistente Konfiguration
- ✅ Persistent nach Reboot
- ✅ Moode WebUI funktioniert
- ✅ Touchscreen-Achsen invertiert

---

**Letzte Aktualisierung:** 30. November 2025  
**Status:** ✅ **FUNKTIONIERT PERFEKT!**  
**WebUI:** http://192.168.178.178/per-config.php#restart-local-display

