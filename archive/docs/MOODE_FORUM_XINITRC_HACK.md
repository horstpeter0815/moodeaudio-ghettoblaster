# Moode Audio Forum Thread 6416 - xinitrc Hack

**Link:** https://moodeaudio.org/forum/showthread.php?tid=6416  
**Thread:** "Waveshare 7.9" HDMI Capacitive Touch Screen on Moode 9"  
**Status:** ✅ ANALYSIERT - xinitrc unterstützt BEIDE (HDMI und DSI)!

---

## ✅ WICHTIG: xinitrc unterstützt HDMI UND DSI!

**KRITISCH:** Die `/home/andre/.xinitrc` Datei enthält Code für **BEIDE**:
- **HDMI:** `xrandr --output HDMI-1 --rotate left`
- **DSI:** `xrandr --output DSI-$DSI_PORT --rotate [normal|left|right|inverted]`

**Der Code funktioniert für DSI genauso!**

---

## Aktuelle xinitrc-Datei (Moode Standard)

**Pfad:** `/home/andre/.xinitrc`

Die Datei enthält bereits vollständige Unterstützung für DSI-Displays:

```bash
# Set HDMI/DSI screen orientation
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
DSI_SCN_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'")
DSI_PORT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_port'")
DSI_SCN_ROTATE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_rotate'")

# HDMI Rotation
if [ $DSI_SCN_TYPE = 'none' ]; then
    if [ $HDMI_SCN_ORIENT = "portrait" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
        DISPLAY=:0 xrandr --output HDMI-1 --rotate left
    fi

# DSI Rotation for Touch2 or Other
# Note that touch1 rotation is configured in config.txt and cmdline.txt
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
```

**Wichtig:** Bei Rotation 90° oder 270° wird `SCREEN_RES` geswappt (`$2","$1` statt `$1","$2`)

---

## Aktuelle Moode-Konfiguration

**Aus der Datenbank:**
```
dsi_port|1
dsi_scn_type|other
dsi_scn_rotate|90
```

**Bedeutung:**
- DSI Port: **1** (DSI-1)
- DSI Screen Type: **other** (nicht Touch1 oder Touch2)
- DSI Rotation: **90°** (rechts)

**Bei 90° Rotation:**
- `SCREEN_RES` wird geswappt: `400,1280` statt `1280,400`
- `xrandr --output DSI-1 --rotate right` wird ausgeführt

---

## Was der User meint: "400 480 minimum pixel height"

**User-Hinweis:** "André" war sein Beitrag - möglicherweise ein spezieller Hack den er entwickelt hat.

**WICHTIG:** Der User korrigierte von "400 80" zu **"480"** oder **"480p"**!

### Kernel-Code zeigt: 480 Pixel ist speziell behandelt!

**In `vc4_dsi.c` (Zeile 896-905):**
```c
if (mode->vdisplay == 480 && mode->vtotal == (480 + 7 + 2 + 22)) {
    // Special handling for 480 pixel height!
    adjusted_mode->vtotal = 480 + 7 + 2 + 45;
    adjusted_mode->crtc_vtotal = 480 + 7 + 2 + 45;
}
```

**In `vc4_firmware_kms.c` (Zeile 1505):**
```c
static const struct drm_display_mode lcd_mode = {
    DRM_MODE("800x480", DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED,
    // Default LCD mode ist 480 Pixel hoch!
```

**Erkenntnis:**
- Der Kernel hat **spezielle Behandlung für 480 Pixel Höhe**
- Der **Default LCD-Mode** ist **800x480** (480 Pixel hoch)
- Unser Display ist **1280x400** (400 Pixel hoch) - **80 Pixel weniger als 480!**

**Mögliche Interpretationen:**
- **400** = Die aktuelle Höhe des Displays (1280x400 = 400 Pixel hoch)
- **480** = Die Minimum-Anforderung oder bevorzugte Höhe für DSI
- **"400 480 minimum pixel height"** = Ein Hack um ein 400-Pixel-Display als 480-Pixel zu melden, oder ein Workaround für die fehlenden 80 Pixel

**Vermutung:** Vielleicht muss das Display-Mode auf 480 Pixel Höhe geändert werden, oder es gibt einen xinitrc-Hack der das Display als 480 hoch meldet, obwohl es 400 ist?

---

## Lösungsansatz aus dem Forum (popeye65)

### 1. cmdline.txt Änderungen

**Hinzufügen:**
```
video=HDMI-A-1:400x1280M@60,rotate=90
```

**Hinweis:** Für DSI wäre es: `video=DSI-1:1280x400M@60` (aber nicht verwenden - wird von Overlay gehandhabt!)

---

### 2. xinitrc SCREENSIZE Swap

**Bei Rotation 90° oder 270°:**

**Original (keine Rotation):**
```bash
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $2","$3 }')"
# Ergebnis: 1280,400
```

**Bei Rotation (Swap $2 und $3):**
```bash
SCREENSIZE="$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')"
# Ergebnis: 400,1280
```

**Grund:** Swap Breite/Höhe für vertikale Displays (400x1280 statt 1280x400)

---

## Wichtige Erkenntnisse

### 1. xinitrc unterstützt bereits DSI
- ✅ **DSI_SCN_TYPE** wird aus Moode-Datenbank gelesen
- ✅ **DSI_PORT** wird aus Moode-Datenbank gelesen  
- ✅ **xrandr** wird für DSI verwendet: `xrandr --output DSI-$DSI_PORT --rotate [normal|left|right|inverted]`
- ✅ Bei Rotation 90/270 wird **SCREEN_RES geswappt**: `$2","$1` statt `$1","$2`

### 2. xinitrc wird für X11 benötigt
- **Nur relevant wenn X11 läuft**
- **Für direktes Framebuffer:** Nicht nötig
- **Aktuell:** X11 läuft NICHT (keine X-Prozesse gefunden)

### 3. Moode-Datenbank steuert xinitrc
- `dsi_scn_type` = `other` → DSI-Code wird verwendet
- `dsi_port` = `1` → `DSI-1` wird verwendet
- `dsi_scn_rotate` = `90` → Rotation rechts + SCREEN_RES Swap

### 4. User-Verzeichnis beachten
- **Nicht `/home/pi/`** (veraltet)
- **Sondern:** `/home/[USER]/.xinitrc` (aktueller Moode User = `andre`)

---

## Forum-Erkenntnisse

### Probleme die User hatten:
1. **Display initialisiert langsam** (>1 Minute)
   - User: popeye65 und pkdick
   - Betrifft Pi 4 und Pi 5
   - Möglicherweise X11 Timeout-Issues

2. **xinitrc Pfad**
   - `/home/pi/.xinitrc` existiert nicht (veralteter User)
   - Verwende `/home/[USER]/.xinitrc`

### Lösungen die funktionierten:
1. **cmdline.txt:** `video=HDMI-A-1:400x1280M@60,rotate=90`
2. **xinitrc:** xrandr Rotation + SCREENSIZE Swap

---

## Für unser DSI-Display

**Aktuelle Konfiguration:**
- `dsi_scn_type` = `other` ✅
- `dsi_port` = `1` ✅
- `dsi_scn_rotate` = `90` ✅

**Was passiert:**
1. xinitrc liest `dsi_scn_type=other` → DSI-Code wird verwendet
2. xinitrc liest `dsi_port=1` → `DSI-1` wird verwendet
3. xinitrc liest `dsi_scn_rotate=90` → Rotation rechts + SCREEN_RES Swap
4. `xrandr --output DSI-1 --rotate right` wird ausgeführt
5. `SCREEN_RES` wird geswappt: `400,1280` statt `1280,400`

**Problem:** X11 läuft aktuell NICHT, daher wird xinitrc nicht ausgeführt!

---

## Fazit

**Status:** ✅ xinitrc unterstützt bereits DSI vollständig!  
**Problem:** X11 läuft nicht, daher wird xinitrc nicht ausgeführt  
**Lösung:** X11 starten oder direktes Framebuffer verwenden

**Relevanz für unser Problem:**
- ✅ xinitrc-Code ist bereits vorhanden und korrekt
- ❌ X11 läuft nicht → xinitrc wird nicht ausgeführt
- ✅ SCREENSIZE-Swap funktioniert bei Rotation
- ✅ xrandr-Trick funktioniert für DSI

**Aktion:** 
1. X11 starten (falls gewünscht)
2. Oder direktes Framebuffer verwenden (aktueller Ansatz)

---

**Quelle:** https://moodeaudio.org/forum/showthread.php?tid=6416  
**User-Hinweis:** "André" war sein Beitrag - möglicherweise ein spezieller Hack für "400 80 minimum pixel height"
