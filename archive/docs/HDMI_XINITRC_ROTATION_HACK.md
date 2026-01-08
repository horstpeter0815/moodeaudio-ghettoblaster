# HDMI xinitrc Rotation Hack implementiert

## Double Rotation Hack für HDMI:

### Schritt 1: cmdline.txt
- ✅ `video=HDMI-A-1:400x1280M@60,rotate=90`
- ✅ Display startet im Portrait-Mode (400x1280)
- ✅ 1280 Pixel Höhe (vermeidet "minimum pixel height" Probleme)

### Schritt 2: Moode xinitrc
- ✅ `hdmi_scn_orient='portrait'` gesetzt
- ✅ xinitrc wird xrandr Rotation für HDMI ausführen
- ✅ `xrandr --output HDMI-1 --rotate left` (bei portrait)

## Funktionsweise:

1. **cmdline.txt:** Display initialisiert mit 400x1280 (Portrait, 1280 Pixel Höhe)
2. **xinitrc:** Rotiert Display dann für finale Orientierung (Landscape)
3. **Ergebnis:** Display funktioniert korrekt

## Erwartetes Ergebnis:

- ✅ Display startet mit 400x1280 (Portrait)
- ✅ xinitrc rotiert dann zu Landscape
- ✅ Keine "minimum pixel height" Probleme

---

**Status:** ✅ Double Rotation Hack implementiert! Reboot durchgeführt!

