# Rotation-Fix - Detaillierte Anleitung

## Problem
Display zeigt Bild, aber Rotation funktioniert nicht korrekt. Bild ist nicht richtig orientiert.

## Lösung

### 1. xinitrc Rotation-Befehl

Die Rotation muss in `/home/andre/.xinitrc` korrekt gesetzt werden:

```bash
xrandr --output HDMI-A-2 --mode 1280x400 --rotate right
```

**Wichtig:** 
- Modus muss zuerst gesetzt werden (1280x400 oder 400x1280)
- Dann Rotation anwenden (`--rotate right`)
- Für Landscape von Portrait: `--rotate right` oder `--rotate left`

### 2. Touchscreen Matrix anpassen

Für `--rotate right` muss die Touchscreen-Matrix in `/etc/X11/xorg.conf.d/99-touchscreen.conf` sein:

```
Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
```

**Matrix für verschiedene Rotationen:**
- `--rotate normal`: `1 0 0 0 1 0 0 0 1`
- `--rotate left`: `0 -1 0 1 0 0 0 0 1`
- `--rotate right`: `0 1 0 -1 0 1 0 0 1`
- `--rotate inverted`: `-1 0 0 0 -1 0 0 0 1`

### 3. Reihenfolge in xinitrc

```bash
# 1. Warte auf X11
sleep 2

# 2. Setze Display-Modus
xrandr --output HDMI-A-2 --mode 1280x400

# 3. Wende Rotation an
xrandr --output HDMI-A-2 --rotate right

# 4. Setze Framebuffer-Größe
xrandr --fb 1280x400

# 5. Starte Chromium
chromium-browser --kiosk --window-size=1280,400 http://localhost
```

### 4. Verifikation

```bash
# Prüfe aktuelle Rotation
xrandr --output HDMI-A-2 --query | grep -E "current|connected"

# Teste Touchscreen
xinput list
xinput test <touchscreen-device-id>
```

## Script: FIX_ROTATION.sh

Das Script macht automatisch:
1. Backup von xinitrc
2. Entfernt alte Rotation-Befehle
3. Fügt korrekte Rotation hinzu
4. Passt Touchscreen-Matrix an
5. Testet Rotation
6. Erstellt Screenshot

## Troubleshooting

### Rotation wird nicht angewendet
- Prüfe ob X11 läuft: `pgrep Xorg`
- Prüfe ob Display erkannt: `xrandr`
- Prüfe xinitrc Syntax
- Reboot nach Änderungen

### Touchscreen funktioniert nicht
- Prüfe Device-ID: `xinput list`
- Prüfe Matrix: `xinput list-props <device-id>`
- Teste manuell: `xinput set-prop <device-id> "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1`

### Bild ist gespiegelt
- Falsche Rotation-Richtung
- Matrix falsch
- Teste `--rotate left` statt `right`

