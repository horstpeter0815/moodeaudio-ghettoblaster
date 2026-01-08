# ✅ FUNKTIONIERENDE KONFIGURATION - Raspberry Pi 5 mit Waveshare 7.9" HDMI Display

**Datum:** $(date)  
**Status:** ✅ **FUNKTIONIERT PERFEKT!**  
**Hardware:** Raspberry Pi 5 Model B Rev 1.1  
**Display:** Waveshare 7.9" HDMI LCD (1280x400)  
**OS:** Moode Audio (Debian 13 Trixie, Kernel 6.12.47+rpt-rpi-v8)

---

## 🎯 WICHTIGE ERKENNTNISSE

### Das Problem war:
1. **Chromium Window-Size Konflikt:** Chromium startete mit `--window-size=400,1280` (Portrait), während xrandr `1280x400` (Landscape) zeigte
2. **Display Cut-Off:** Nur oberes Drittel sichtbar, untere 2/3 schwarz
3. **Rotation nicht persistent:** xrandr Rotation wurde nicht in xinitrc gespeichert

### Die Lösung:
1. **Video Parameter:** `400x1280M@60,rotate=90` (Display startet Portrait, wird dann rotiert)
2. **xrandr Rotation:** `--rotate left` (von 400x1280 zu 1280x400)
3. **Chromium Window-Size:** `--window-size=1280,400` (konsistent mit xrandr)
4. **xinitrc:** Rotation wird automatisch bei jedem X11 Start gesetzt

---

## 📋 FINALE KONFIGURATION

### `/boot/firmware/config.txt`

```ini
#########################################
# Funktionierende Config für Pi 5 mit Waveshare 7.9" HDMI LCD
# Diese Config funktioniert PERFEKT!
#########################################

[cm4]
otg_mode=1

[pi5]
# Pi 5 spezifisches KMS Overlay (WICHTIG: vc4-kms-v3d-pi5, nicht generisch!)
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
# Basis-KMS (True KMS)
dtoverlay=vc4-kms-v3d

# Waveshare Panel - HDMI Version (DSI Overlay deaktiviert)
#dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0

# I2C aktivieren
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on

# HDMI aktivieren für HDMI Waveshare Display
hdmi_ignore_hotplug=0
display_auto_detect=1
hdmi_force_hotplug=1
hdmi_blanking=0
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 480 60 6 0 0 0
hdmi_drive=2

# Framebuffer aktivieren
fbcon=map=1

# Firmware-KMS aktivieren (WICHTIG!)
disable_fw_kms_setup=0

# Allgemeine Einstellungen
arm_64bit=1
arm_boost=1
disable_splash=0
disable_overscan=1

# Power Management für DSI Display
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0

# Audio (falls benötigt)
dtparam=audio=on
dtparam=i2s=on
```

### `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=47dfe65d-02 rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
```

**WICHTIG:**
- `video=HDMI-A-2:400x1280M@60,rotate=90` - Display startet Portrait (400x1280), wird dann rotiert
- `HDMI-A-2` - Korrekter HDMI Port für Pi 5

### `/home/andre/.xinitrc`

**WICHTIGE TEILE:**

```bash
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

# HDMI Rotation
if [ $DSI_SCN_TYPE = 'none' ]; then
    DISPLAY=:0 xrandr --output HDMI-2 --rotate left
    if [ $HDMI_SCN_ORIENT = "portrait" ]; then
        DISPLAY=:0 xrandr --output HDMI-2 --rotate left
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
        # DISPLAY=:0 xrandr --output HDMI-2 --mode 1280x400 --panning 1280x400+0+0
    fi
fi

# ... DSI Rotation Code ...

# Launch chromium browser
chromium \
--app="http://localhost/" \
--window-size="1280,400" \
--window-position="0,0" \
--enable-features="OverlayScrollbar" \
--no-first-run \
--disable-infobars \
--disable-session-crashed-bubble \
--kiosk
```

**WICHTIG:**
- `DISPLAY=:0 xrandr --output HDMI-2 --rotate left` - Rotation wird IMMER gesetzt (auch bei landscape)
- `--window-size="1280,400"` - Explizit auf Landscape gesetzt (nicht `$SCREEN_RES`)

### Moode Audio Settings

```sql
hdmi_scn_orient = 'landscape'
dsi_scn_type = 'none'
```

---

## 🔍 AKTUELLER STATUS (FUNKTIONIERT!)

```
xrandr: HDMI-2 connected 1280x400+0+0 left
Chromium: --window-size=1280,400
Framebuffer: 400,1280 (Basis bleibt Portrait, wird rotiert)
```

---

## ✅ ERFOLGS-KRITERIEN

- ✅ Display zeigt vollständiges Bild (keine schwarzen Bereiche)
- ✅ Landscape (1280x400) korrekt
- ✅ Chromium Window-Size = xrandr Resolution (konsistent)
- ✅ Rotation persistent (wird bei jedem X11 Start gesetzt)
- ✅ Keine Cut-Off Probleme
- ✅ Keine I2C Errors
- ✅ System stabil

---

## 🚀 WICHTIGE PUNKTE FÜR ZUKÜNFTIGE UPDATES

1. **Video Parameter:** `400x1280M@60,rotate=90` - NICHT ändern! Display startet Portrait, wird dann rotiert
2. **xinitrc Rotation:** `DISPLAY=:0 xrandr --output HDMI-2 --rotate left` - MUSS bei jedem Start gesetzt werden
3. **Chromium Window-Size:** `--window-size="1280,400"` - Explizit setzen, nicht `$SCREEN_RES` verwenden
4. **HDMI Port:** `HDMI-A-2` für Pi 5 (nicht `HDMI-A-1`)
5. **KMS Overlay:** `vc4-kms-v3d-pi5` für Pi 5 (nicht generisch)

---

## 📝 NOTIZEN

- **Warum Portrait zuerst?** Das Display funktioniert nur, wenn es mit Portrait (400x1280) startet. Die Rotation zu Landscape (1280x400) erfolgt dann über xrandr.
- **Warum explizite Window-Size?** `$SCREEN_RES` wird aus dem Framebuffer gelesen, der Portrait (400,1280) ist. Chromium braucht aber Landscape (1280,400).
- **Warum doppelte Rotation?** Die erste Rotation in xinitrc setzt immer Landscape, auch wenn Moode auf landscape steht. Das ist notwendig, weil das Display mit Portrait startet.

---

## 🎉 ERGEBNIS

**DAS DISPLAY FUNKTIONIERT PERFEKT!**

- ✅ Vollständiges Bild sichtbar
- ✅ Landscape (1280x400)
- ✅ Keine schwarzen Bereiche
- ✅ Konsistente Konfiguration
- ✅ Persistent nach Reboot

---

**Letzte Aktualisierung:** $(date)  
**Status:** ✅ **FUNKTIONIERT PERFEKT!**

