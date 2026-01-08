# HDMI-2 Rotation Fix

## Problem gefunden:

- ❌ **xinitrc rotierte HDMI-1**, aber **HDMI-2 ist connected**
- ❌ **Bild war abgeschnitten** (400x1280 statt 1280x400)

## Lösung:

1. ✅ **xinitrc korrigiert:** HDMI-2 statt HDMI-1
2. ✅ **Manuelle Rotation gesetzt:** `xrandr --output HDMI-2 --rotate left`
3. ✅ **Video Parameter:** `HDMI-A-2:1280x400M@60` (für HDMI-2)

## Status:

- ✅ **X11 läuft** (Chromium zeigt Moode UI)
- ✅ **HDMI-2 ist connected** (400x1280 Portrait)
- ✅ **Rotation funktioniert:** `xrandr --output HDMI-2 --rotate left` → 1280x400 Landscape
- ✅ **xinitrc korrigiert:** Rotiert jetzt HDMI-2 beim nächsten X11 Start

## Erwartetes Ergebnis:

- ✅ Bild ist nicht mehr abgeschnitten
- ✅ Display zeigt 1280x400 (Landscape)
- ✅ xinitrc rotiert automatisch beim nächsten Start

---

**Status:** ✅ Rotation funktioniert! Bild sollte jetzt korrekt sein!

