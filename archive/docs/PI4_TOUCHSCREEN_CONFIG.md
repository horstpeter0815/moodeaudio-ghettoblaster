# Pi 4 + Waveshare 7.9" Touchscreen Konfiguration

**Datum:** 30. November 2025  
**Status:** ✅ Konfiguriert  
**Hardware:** Raspberry Pi 4 + Waveshare 7.9" HDMI Capacitive Touch Screen

---

## 🎯 ZUSAMMENFASSUNG

**Touchscreen-Inversion für beide Achsen konfiguriert:**
- ✅ `xinput` installiert
- ✅ Inversion für `vc4-hdmi-0` (ID 7) gesetzt
- ✅ Inversion für `vc4-hdmi-1` (ID 8) gesetzt
- ✅ Konfiguration in `.xinitrc` gespeichert

---

## 📋 KONFIGURATION

### Touchscreen-Inversion

**Matrix:** `-1 0 1 0 -1 1 0 0 1`

**Bedeutung:**
- `-1 0 1` - X-Achse invertiert (links ↔ rechts)
- `0 -1 1` - Y-Achse invertiert (oben ↔ unten)
- `0 0 1` - Homogene Koordinate

### `.xinitrc` Eintrag

```bash
# Touchscreen Inversion (beide Achsen) - für Waveshare 7.9" Display
export DISPLAY=:0
# Invertiere beide vc4-hdmi Geräte (Touchscreen könnte über HDMI verbunden sein)
xinput set-prop 7 "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1 2>/dev/null || true
xinput set-prop 8 "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1 2>/dev/null || true
```

**Position:** Nach `xrandr` Rotation, vor Chromium-Start

---

## 🔍 VERIFIZIERUNG

### 1. xinput Status prüfen

```bash
export DISPLAY=:0
xinput list
```

**Erwartete Ausgabe:**
```
⎡ Virtual core pointer                    	id=2	[master pointer  (3)]
⎜   ↳ vc4-hdmi-0                              	id=7	[slave  pointer  (2)]
⎜   ↳ vc4-hdmi-1                              	id=8	[slave  pointer  (2)]
```

### 2. Transformation Matrix prüfen

```bash
export DISPLAY=:0
xinput list-props 7 | grep "Coordinate Transformation Matrix"
xinput list-props 8 | grep "Coordinate Transformation Matrix"
```

**Erwartete Ausgabe:**
```
Coordinate Transformation Matrix (152):	-1.000000, 0.000000, 1.000000, 0.000000, -1.000000, 1.000000, 0.000000, 0.000000, 1.000000
```

### 3. Touchscreen testen

**Manuell:**
- Display berühren
- Prüfen, ob Cursor an der richtigen Stelle erscheint
- Falls nicht: "Rotate Touch" Button auf dem Display mehrmals drücken

---

## 🔧 TROUBLESHOOTING

### Problem: Touchscreen funktioniert nicht

**Symptom:**
- Keine Reaktion auf Berührung
- Cursor erscheint an falscher Stelle

**Lösung:**
1. Prüfe xinput: `xinput list`
2. Prüfe Matrix: `xinput list-props 7 | grep Coordinate`
3. Setze Matrix manuell:
   ```bash
   export DISPLAY=:0
   xinput set-prop 7 "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
   xinput set-prop 8 "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
   ```
4. Falls nötig: "Rotate Touch" Button auf dem Display drücken

### Problem: Falsche Geräte-ID

**Symptom:**
- `xinput set-prop` gibt Fehler: "unable to find device"

**Lösung:**
1. Finde korrekte ID: `xinput list`
2. Aktualisiere `.xinitrc` mit korrekter ID

### Problem: Matrix wird nicht angewendet

**Symptom:**
- Nach Reboot ist Matrix wieder `1 0 0 0 1 0 0 0 1`

**Lösung:**
1. Prüfe `.xinitrc`: `grep "Coordinate Transformation Matrix" /home/andre/.xinitrc`
2. Stelle sicher, dass Zeilen nach `xrandr` und vor Chromium stehen
3. Prüfe X Server Start: `systemctl status localdisplay.service`

---

## 📝 HINWEISE

### Waveshare 7.9" Display

**Laut Moode Forum:**
> "The touch screen worked out of the box. However, you may need to press the 'Rotate Touch' button a few times until it works correctly. The display modules saves the rotation setting internally."

**Wichtig:**
- Touchscreen ist kapazitiv
- Verbindung über HDMI (nicht USB/I2C)
- "Rotate Touch" Button auf dem Display-Modul selbst

### vc4-hdmi Geräte

**Warum beide Geräte?**
- `vc4-hdmi-0` = HDMI Port 0
- `vc4-hdmi-1` = HDMI Port 1
- Touchscreen könnte über einen der beiden Ports verbunden sein
- Inversion für beide setzen, um sicherzugehen

---

## 🔄 PERSISTENZ

**Konfiguration wird automatisch angewendet:**
- ✅ In `.xinitrc` gespeichert
- ✅ Wird bei jedem X Server Start ausgeführt
- ✅ Vor Chromium-Start angewendet

**Nach Reboot:**
1. X Server startet (`localdisplay.service`)
2. `.xinitrc` wird ausgeführt
3. Touchscreen-Inversion wird angewendet
4. Chromium startet

---

## 📚 REFERENZEN

- [Moode Forum: Waveshare 7.9" Display](https://moodeaudio.org/forum/showthread.php?tid=6416)
- [xinput Documentation](https://www.x.org/releases/X11R7.5/doc/man/man1/xinput.1.html)
- [Coordinate Transformation Matrix](https://wiki.ubuntu.com/X/InputCoordinateTransformation)

---

**Letzte Aktualisierung:** 30. November 2025  
**Status:** ✅ Konfiguriert und dokumentiert

