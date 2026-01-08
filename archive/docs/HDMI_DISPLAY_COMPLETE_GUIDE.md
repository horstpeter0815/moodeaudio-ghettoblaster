# HDMI Display - Komplette Anleitung für Raspberry Pi 5 mit Moode Audio

**Hardware:** Raspberry Pi 5, Waveshare 7.9" HDMI LCD (1280x400)  
**Software:** Moode Audio 10.0.0  
**Status:** ✅ **FUNKTIONIERT PERFEKT**

---

## 📋 Vollständige Konfiguration

### 1. `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=e77cf027-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE consoleblank=0 video=HDMI-A-2:400x1280M@60,rotate=90
```

**Erklärung:**
- `video=HDMI-A-2:400x1280M@60,rotate=90` - Display startet im Portrait-Modus (400x1280) und wird vom Kernel um 90° rotiert
- `HDMI-A-2` - HDMI Port für Raspberry Pi 5 (Pi 4 verwendet `HDMI-A-1`)

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

**Erklärung:**
- `dtoverlay=vc4-kms-v3d-pi5,noaudio` - Pi 5 spezifisches KMS Overlay
- `hdmi_cvt 1280 400 60 6 0 0 0` - Definiert Custom-Mode: 1280x400 @ 60Hz
- `hdmi_mode=87` - Verwendet den Custom-Mode
- `hdmi_group=2` - DMT (Display Monitor Timings)

### 3. `/home/andre/.xinitrc` (Vollständig)

```bash
#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright 2014 The moOde audio player project / Tim Curtis
#

# Turn off display power management
xset -dpms

# Screensaver timeout in secs or 'off' for no timeout
xset s 600

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

# Capture native screen size
fgrep "#dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt
if [ $? -ne 0 ]; then
    SCREEN_RES=$(kmsprint | awk '$1 == "FB" {print $3}' | awk -F"x" '{print $1","$2}')
else
    SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')
fi

# Set HDMI/DSI screen orientation
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
DSI_SCN_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'")
DSI_PORT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_port'")
DSI_SCN_ROTATE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_rotate'")

# WICHTIG: Rotation IMMER setzen (Display startet Portrait, wird zu Landscape)
if [ $DSI_SCN_TYPE = 'none' ]; then
    DISPLAY=:0 xrandr --output HDMI-2 --rotate left
    if [ $HDMI_SCN_ORIENT = "portrait" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
    fi
elif [ $DSI_SCN_TYPE = '2' ] || [ $DSI_SCN_TYPE = 'other' ]; then
    if [ $DSI_SCN_ROTATE = "0" ]; then
        DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate normal
    elif [ $DSI_SCN_ROTATE = "90" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
        DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate right
    elif [ $DSI_SCN_ROTATE = "180" ]; then
        DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate inverted
    elif [ $DSI_SCN_ROTATE = "270" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
        DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate left
    fi
fi

# Launch WebUI or Peppy
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'")
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'")
PEPPY_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display_type'")
if [ $WEBUI_SHOW = "1" ]; then
    # Clear browser cache
    $(/var/www/util/sysutil.sh clearbrcache)
    # Launch chromium browser
    echo "Starte Chromium mit --window-size=1280,400..."
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
    
    # Warte auf Chromium
    sleep 10
    
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
elif [ $PEPPY_SHOW = "1" ]; then
    if [ $PEPPY_TYPE = 'meter' ]; then
        cd /opt/peppymeter && python3 peppymeter.py
    else
        cd /opt/peppyspectrum && python3 spectrum.py
    fi
fi
```

**Kritische Punkte:**
- **`--no-sandbox`** - MUSS vorhanden sein, sonst wird Chromium "Killed"
- **`xrandr --output HDMI-2 --rotate left`** - Rotation wird IMMER gesetzt
- **`--window-size="1280,400"`** - Explizit setzen, nicht `$SCREEN_RES` verwenden
- **Touchscreen-Inversion** - Beide Achsen werden invertiert

---

## 🔑 Warum diese Konfiguration?

### 1. Warum `video=400x1280M@60,rotate=90`?

Das Display funktioniert nur, wenn es mit Portrait (400x1280) startet. Die Rotation zu Landscape (1280x400) erfolgt dann über xrandr. Der `rotate=90` Parameter im Kernel sorgt für die initiale Rotation.

### 2. Warum `xrandr --rotate left`?

Auch wenn das Display bereits vom Kernel rotiert wurde, muss xrandr die Rotation nochmal setzen, um sicherzustellen, dass X11 den korrekten Modus verwendet.

### 3. Warum `--window-size="1280,400"` explizit?

`$SCREEN_RES` wird aus dem Framebuffer gelesen, der Portrait (400,1280) ist. Chromium braucht aber Landscape (1280,400). Daher muss die Window-Size explizit gesetzt werden.

### 4. Warum `--no-sandbox`?

Chromium wird ohne diesen Parameter "Killed" auf Raspberry Pi 5. Das ist ein bekanntes Problem mit Chromium auf ARM-Systemen.

### 5. Warum Touchscreen-Inversion?

Nach der Display-Rotation müssen die Touchscreen-Achsen invertiert werden, damit die Touch-Koordinaten mit dem Display übereinstimmen.

---

## ✅ Installation

### Schritt 1: cmdline.txt anpassen

```bash
sudo nano /boot/firmware/cmdline.txt
```

Füge am Ende hinzu:
```
video=HDMI-A-2:400x1280M@60,rotate=90
```

**Für Pi 4:** Verwende `HDMI-A-1` statt `HDMI-A-2`

### Schritt 2: config.txt anpassen

```bash
sudo nano /boot/firmware/config.txt
```

Stelle sicher, dass folgende Zeilen vorhanden sind:
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
```

### Schritt 3: .xinitrc anpassen

```bash
nano ~/.xinitrc
```

Kopiere den vollständigen Inhalt aus Abschnitt 3 oben.

### Schritt 4: xinput installieren (für Touchscreen)

```bash
sudo apt-get update
sudo apt-get install -y xinput
```

### Schritt 5: Reboot

```bash
sudo reboot
```

---

## 🔍 Diagnose

### Framebuffer prüfen

```bash
fbset -s
```

**Erwartet:** `mode "400x1280"` (Portrait, wird dann rotiert)

### Display-Mode prüfen

```bash
export DISPLAY=:0
xrandr --query | grep -A3 "HDMI-2 connected"
```

**Erwartet:** `HDMI-2 connected 1280x400+0+0 left` (Landscape, rotiert)

### Chromium prüfen

```bash
pgrep -f chromium
xwininfo -root -tree | grep -i chromium
```

**Erwartet:** Chromium-Prozesse laufen, Fenster "GhettoPi5-2 Player - Chromium" vorhanden

### Touchscreen prüfen

```bash
export DISPLAY=:0
xinput list
xinput list-props 6 | grep "Coordinate Transformation Matrix"
```

**Erwartet:** Touchscreen ID 6, Matrix: `-1.000000, 0.000000, 1.000000, 0.000000, -1.000000, 1.000000`

---

## 🛠️ Troubleshooting

### Problem: Schwarzer Bildschirm mit Backlight

**Lösung:**
1. Prüfe ob Chromium läuft: `pgrep -f chromium`
2. Prüfe ob `--no-sandbox` in .xinitrc vorhanden ist
3. Prüfe Display-Mode: `xrandr --query`
4. Starte Chromium manuell: `DISPLAY=:0 chromium --no-sandbox --kiosk http://localhost/ &`

### Problem: Chromium wird "Killed"

**Lösung:**
- Stelle sicher, dass `--no-sandbox` in .xinitrc vorhanden ist
- Prüfe Logs: `journalctl -u localdisplay.service -n 50`

### Problem: Display zeigt Portrait statt Landscape

**Lösung:**
1. Prüfe cmdline.txt: `cat /boot/firmware/cmdline.txt | grep video=`
2. Prüfe ob xrandr Rotation gesetzt wird: `xrandr --query | grep HDMI-2`
3. Setze Rotation manuell: `DISPLAY=:0 xrandr --output HDMI-2 --rotate left`

### Problem: Touchscreen funktioniert nicht korrekt

**Lösung:**
1. Prüfe Touchscreen-ID: `xinput list | grep -i touch`
2. Prüfe Transformation Matrix: `xinput list-props [ID] | grep Matrix`
3. Setze Matrix manuell: `xinput set-prop [ID] "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1`

---

## 📝 Wichtige Dateien

- `/boot/firmware/cmdline.txt` - Boot-Parameter
- `/boot/firmware/config.txt` - Hardware-Konfiguration
- `/home/andre/.xinitrc` - X11 Start-Script
- `/usr/local/lib/moode-display/xinitrc.waveshare` - Template für automatische Wiederherstellung

---

## 🎯 Status

**✅ FUNKTIONIERT PERFEKT!**

- ✅ Display zeigt vollständiges Bild (1280x400 Landscape)
- ✅ Chromium läuft mit Renderer-Prozessen
- ✅ Moode WebUI erreichbar
- ✅ Touchscreen-Achsen invertiert
- ✅ Konfiguration persistent nach Reboot

---

**Letzte Aktualisierung:** 30. November 2025  
**Status:** ✅ **FUNKTIONIERT PERFEKT**

