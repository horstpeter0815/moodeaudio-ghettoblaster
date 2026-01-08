# xinitrc Modifications Required - Forum Steps

**Quelle:** Moode Audio Forum Thread 6416  
**User:** popeye65  
**Link:** https://moodeaudio.org/forum/showthread.php?tid=6416

---

## ✅ Exakte Schritte aus dem Forum

### Schritt 1: Vor den "xset" Commands hinzufügen

```bash
DISPLAY=:0 xrandr --output HDMI-1 --rotate left
```

**Für unser DSI Display:**
```bash
DISPLAY=:0 xrandr --output DSI-1 --rotate left
```
(oder `--rotate right` je nach gewünschter Rotation)

---

### Schritt 2: SCREENSIZE-Zeile ändern - Swap $2 und $3

**Original:**
```bash
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $2","$3 }')"
```

**Geändert (swap $2 und $3):**
```bash
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $3","$2 }')"
```

**Erklärung:**
- `$2` = Breite (z.B. 1280)
- `$3` = Höhe (z.B. 400)
- **Swap** = Höhe,Breite statt Breite,Höhe
- Ergebnis: `400,1280` statt `1280,400` (für rotierte Displays)

---

## Aktuelle xinitrc-Struktur

**Aktuelle Datei:** `/home/andre/.xinitrc`

**Aktueller Code-Abschnitt:**
```bash
# Turn off display power management
xset -dpms

# Screensaver timeout in secs or 'off' for no timeout
xset s 600

# Capture native screen size
fgrep "#dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt
if [ $? -ne 0 ]; then
    SCREEN_RES=$(kmsprint | awk '$1 == "FB" {print $3}' | awk -F"x" '{print $1","$2}')
else
    SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')
fi
```

---

## ⚠️ WICHTIG: Moode xinitrc ist komplexer!

**Moode verwendet bereits:**
1. **DSI-Konfiguration** aus der Datenbank (`dsi_scn_type`, `dsi_port`, `dsi_scn_rotate`)
2. **Conditional Logic** für HDMI vs DSI
3. **SCREEN_RES** (nicht SCREENSIZE) wird bereits geswappt bei Rotation 90/270

**Aktueller DSI-Code:**
```bash
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

---

## 🎯 Was muss angepasst werden?

### Option 1: Forum-Schritte direkt anwenden (einfach)

**Vor `xset -dpms` hinzufügen:**
```bash
# Forum Hack: Force DSI-1 rotation
DISPLAY=:0 xrandr --output DSI-1 --rotate left

# Turn off display power management
xset -dpms
```

**SCREEN_RES-Zeile ändern:**
```bash
# Original
SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')

# Geändert (swap)
SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $3","$2}')
```

---

### Option 2: Moode-Logik beibehalten (empfohlen)

**Moode macht bereits das Richtige:**
- ✅ xrandr wird bereits für DSI aufgerufen
- ✅ SCREEN_RES wird bereits geswappt bei Rotation 90/270
- ✅ Konfiguration kommt aus Moode-Datenbank

**Möglicherweise fehlt:**
- ❌ Die xrandr-Zeile wird möglicherweise ZU SPÄT aufgerufen (nach xset)
- ❌ SCREEN_RES wird möglicherweise nach xrandr geändert (falsche Reihenfolge)

---

## 💡 Empfehlung

**Der Forum-Hack macht zwei Dinge:**
1. **xrandr VOR xset** → Display wird früher initialisiert
2. **SCREEN_RES Swap IMMER** → Nicht nur bei Rotation, sondern immer swap

**Mögliche Lösung:**
- xrandr-Zeile VOR xset verschieben
- SCREEN_RES-Zeile IMMER swappen (nicht nur bei Rotation)

---

## 🔧 Implementierung

**Zu prüfen:**
1. Wird xrandr aktuell vor oder nach xset aufgerufen?
2. Wird SCREEN_RES bereits geswappt, oder muss es immer geswappt werden?
3. Muss die Reihenfolge geändert werden?

**Nächster Schritt:** Prüfe die aktuelle xinitrc und wende die Änderungen an!

---

**Status:** Bereit für Implementierung - warte auf Bestätigung!

