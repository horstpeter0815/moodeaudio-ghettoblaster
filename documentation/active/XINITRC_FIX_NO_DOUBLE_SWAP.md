# xinitrc Fix - Kein Doppel-Swap!

**Problem:** Moode swappt bereits bei Rotation 90/270 - wenn wir auch die SCREENSIZE-Zeile swappen → **doppelt getauscht!**

---

## ✅ Richtige Implementierung

### Schritt 1: cmdline.txt
**Aktuell:**
```
video=DSI-1:1280x400@60
```

**Ändern zu (nach Forum):**
```
video=DSI-1:1280x400M@60,rotate=90
```

**Hinzufügen:** `M@60,rotate=90` am Ende

---

### Schritt 2: xinitrc - xrandr VOR xset verschieben

**AKTUELL (falsche Reihenfolge):**
```bash
# Turn off display power management
xset -dpms

# Screensaver timeout
xset s 600

# Capture native screen size
SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')

# DSI Rotation (später)
elif [ $DSI_SCN_ROTATE = "90" ]; then
    SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')  # SWAP!
    DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate right
```

**GEÄNDERT (xrandr VOR xset):**
```bash
# Set HDMI/DSI screen orientation VOR xset!
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
DSI_SCN_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'")
DSI_PORT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_port'")
DSI_SCN_ROTATE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_rotate'")

if [ $DSI_SCN_TYPE = 'none' ]; then
    if [ $HDMI_SCN_ORIENT = "portrait" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
        DISPLAY=:0 xrandr --output HDMI-1 --rotate left
    fi
elif [ $DSI_SCN_TYPE = '2' ] || [ $DSI_SCN_TYPE = 'other' ]; then
    if [ $DSI_SCN_ROTATE = "0" ]; then
        DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate normal
    elif [ $DSI_SCN_ROTATE = "90" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')  # SWAP (nur hier!)
        DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate right
    elif [ $DSI_SCN_ROTATE = "180" ]; then
        DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate inverted
    elif [ $DSI_SCN_ROTATE = "270" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')  # SWAP (nur hier!)
        DISPLAY=:0 xrandr --output DSI-$DSI_PORT --rotate left
    fi
fi

# Turn off display power management (NACH xrandr!)
xset -dpms

# Screensaver timeout
xset s 600

# Capture native screen size (NACH xrandr und Rotation!)
fgrep "#dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt
if [ $? -ne 0 ]; then
    SCREEN_RES=$(kmsprint | awk '$1 == "FB" {print $3}' | awk -F"x" '{print $1","$2}')
else
    SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')  # KEIN SWAP hier!
fi
```

---

## ⚠️ WICHTIG: KEIN SWAP in SCREENSIZE-Zeile!

**FALSCH (doppelt getauscht):**
```bash
SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $3","$2}')  # SWAP hier
# + später bei Rotation 90:
SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')     # SWAP nochmal → DOPPELT!
```

**RICHTIG (nur bei Rotation swappen):**
```bash
SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')  # KEIN SWAP hier
# + später bei Rotation 90:
SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')     # SWAP nur hier → EINMAL!
```

---

## 📝 Zusammenfassung der Änderungen

1. ✅ **cmdline.txt**: `video=DSI-1:1280x400M@60,rotate=90` hinzufügen
2. ✅ **xinitrc**: DSI-Rotation-Code VOR `xset -dpms` verschieben
3. ❌ **KEIN** Swap in der SCREENSIZE-Zeile (Moode macht das schon bei Rotation!)

---

**Status:** Bereit für Implementierung ohne Doppel-Swap!

