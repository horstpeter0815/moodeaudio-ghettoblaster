# Chromium Portrait Fix

## Problem:

- ✅ **xrandr:** `400x1280` (Portrait - korrekt!)
- ❌ **Chromium:** `--window-size=1280,400` (Landscape - falsch!)
- ❌ **KONFLIKT!** → Bild ist abgeschnitten

## Ursache:

- `SCREEN_RES` wird aus Framebuffer gelesen
- Framebuffer ist `400,1280` (Portrait)
- Aber Chromium verwendet alte Window-Size `1280,400`

## Lösung:

1. ✅ **Window-Size explizit auf 400,1280 gesetzt** in xinitrc
2. ✅ **X11 Service neu gestartet**
3. ✅ **Chromium startet jetzt mit korrekter Window-Size**

## Finale Config:

- **xrandr:** 400x1280 ✅
- **Chromium:** 400,1280 ✅
- **Framebuffer:** 400,1280 ✅
- **Video Parameter:** 400x1280M@60,rotate=90 ✅

## Erwartetes Ergebnis:

- ✅ Beide konsistent (400x1280 Portrait)
- ✅ Display zeigt vollständiges Bild
- ✅ Keine schwarzen Bereiche

---

**Status:** ✅ Chromium Window-Size korrigiert! Beide sind jetzt Portrait!

