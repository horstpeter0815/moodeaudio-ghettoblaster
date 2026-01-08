# Rotation angewendet

## Status:

- ✅ **Framebuffer:** 1280x400 (Landscape) - korrekt!
- ✅ **xrandr Rotation gesetzt:** `--output HDMI-2 --rotate left`
- ✅ **xinitrc korrigiert:** Rotiert HDMI-2 beim nächsten Start

## Lösung:

1. **video Parameter:** `HDMI-A-2:1280x400M@60` (setzt Framebuffer)
2. **xrandr Rotation:** `--output HDMI-2 --rotate left` (rotiert X11)
3. **xinitrc:** Rotiert automatisch beim nächsten X11 Start

## Erwartetes Ergebnis:

- ✅ Bild ist nicht mehr abgeschnitten
- ✅ Display zeigt 1280x400 (Landscape)
- ✅ Beim nächsten Reboot rotiert xinitrc automatisch

---

**Status:** ✅ Rotation angewendet! Bild sollte jetzt korrekt sein!

