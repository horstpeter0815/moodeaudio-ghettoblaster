# Pi 4 HDMI Konfiguration - Korrektur

**Datum:** 30. November 2025  
**Problem:** HDMI-Konfiguration in config.txt war unvollständig  
**Status:** ✅ Korrigiert

---

## 🔍 PROBLEM

**Aktuelle config.txt hatte:**
- `hdmi_group=0` (falsch, sollte `2` sein)
- Fehlte `hdmi_mode=87` und `hdmi_cvt 1280 400 60 6 0 0 0`
- Fehlte `dtoverlay=vc4-kms-v3d-pi4,noaudio` in `[pi4]` Sektion
- Doppelte/inkorrekte `hdmi_force_hotplug` Einträge

**Folge:**
- Display zeigte Streifen
- 1280x400 Mode wurde nicht korrekt erkannt
- Rotation funktionierte nicht richtig

---

## ✅ LÖSUNG

### Korrigierte `/boot/firmware/config.txt`

```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
hdmi_drive=2
hdmi_blanking=1
hdmi_force_edid_audio=1
hdmi_force_hotplug=1
```

**Wichtige Punkte:**
- ✅ `[pi4]` Sektion für Pi 4 spezifische Overlays
- ✅ `dtoverlay=vc4-kms-v3d-pi4,noaudio` - KMS für Pi 4, HDMI Audio deaktiviert
- ✅ `hdmi_group=2` - DMT (Display Monitor Timings)
- ✅ `hdmi_mode=87` - Custom Mode
- ✅ `hdmi_cvt 1280 400 60 6 0 0 0` - Custom Resolution für Waveshare Display

### `/boot/firmware/cmdline.txt`

```
video=HDMI-A-1:400x1280M@60,rotate=90
```

**Bedeutung:**
- Display startet im Portrait-Modus (400x1280)
- Wird dann von `xrandr` in `.xinitrc` zu Landscape (1280x400) rotiert

---

## 🔄 NÄCHSTE SCHRITTE

1. **Reboot durchführen:**
   ```bash
   sudo reboot
   ```

2. **Nach Reboot prüfen:**
   - Display zeigt 1280x400 Landscape
   - Keine Streifen sichtbar
   - Touchscreen funktioniert mit 180° Inversion

3. **Falls Probleme:**
   - Prüfe `xrandr --query` für Display-Status
   - Prüfe `.xinitrc` für Rotation und Mode-Setup
   - Prüfe `dmesg | grep -i hdmi` für HDMI-Fehler

---

## 📝 TECHNISCHE DETAILS

### hdmi_cvt Parameter

```
hdmi_cvt 1280 400 60 6 0 0 0
```

**Bedeutung:**
- `1280` - Breite in Pixeln
- `400` - Höhe in Pixeln
- `60` - Refresh Rate in Hz
- `6` - Aspect Ratio (16:9 = 1, 4:3 = 2, 16:10 = 3, etc.)
- `0` - 3D Flag
- `0` - Reduced Blanking
- `0` - Progressive

### hdmi_mode=87

**Bedeutung:**
- Mode 87 = Custom Mode (verwendet `hdmi_cvt`)

### dtoverlay=vc4-kms-v3d-pi4,noaudio

**Bedeutung:**
- `vc4-kms-v3d-pi4` - VideoCore 4 KMS Driver für Pi 4
- `noaudio` - HDMI Audio deaktiviert (für HiFiBerry AMP100)

---

## 🔧 TROUBLESHOOTING

### Problem: Display zeigt immer noch Streifen

**Lösung:**
1. Prüfe ob Reboot durchgeführt wurde
2. Prüfe `xrandr --query` für aktuelle Auflösung
3. Prüfe ob `1280x400_60.00` Mode vorhanden ist
4. Setze Mode manuell: `xrandr --output HDMI-1 --mode "1280x400_60.00"`

### Problem: Display zeigt 400x1280 statt 1280x400

**Lösung:**
1. Prüfe `.xinitrc` - sollte `xrandr --output HDMI-1 --rotate left` enthalten
2. Prüfe ob Mode vor Rotation gesetzt wird
3. Setze manuell: `xrandr --output HDMI-1 --mode "1280x400_60.00" --rotate left`

### Problem: HDMI wird nicht erkannt

**Lösung:**
1. Prüfe `hdmi_force_hotplug=1` in config.txt
2. Prüfe HDMI-Kabel-Verbindung
3. Prüfe `dmesg | grep -i hdmi` für Fehler

---

**Letzte Aktualisierung:** 30. November 2025  
**Status:** ✅ Korrigiert, Reboot erforderlich

