# HDMI Config korrigiert

## Problem gefunden:

- ❌ `hdmi_group=0` statt `hdmi_group=2`
- ❌ `hdmi_mode=87` fehlte
- ❌ `hdmi_cvt 1280 400 60 6 0 0 0` fehlte

## Durchgeführte Korrekturen:

1. ✅ `hdmi_group=0` → `hdmi_group=2`
2. ✅ `hdmi_mode=87` hinzugefügt
3. ✅ `hdmi_cvt 1280 400 60 6 0 0 0` hinzugefügt
4. ✅ Reboot durchgeführt

## Aktuelle Status:

- ✅ Framebuffer: 400,1280 (Portrait) - korrekt!
- ✅ HDMI-A-1 und HDMI-A-2 erkannt
- ✅ Config korrigiert

## Erwartetes Ergebnis:

- ✅ HDMI sollte jetzt mit korrekten Parametern funktionieren
- ✅ 1280x400 Auflösung
- ✅ Portrait-Modus

---

**Status:** ✅ Config korrigiert! Reboot durchgeführt!

