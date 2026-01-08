# Chromium Window-Size Fix

## Problem gefunden:

- ❌ **Chromium:** `--window-size=400,1280` (Portrait)
- ❌ **xrandr:** `1280x400` (Landscape)
- ❌ **KONFLIKT!** → Bild ist abgeschnitten

## Lösung:

1. ✅ **Chromium Window-Size korrigiert:** `--window-size=1280,400`
2. ✅ **localdisplay.service geändert**
3. ✅ **Service neu gestartet**

## Warum das Problem:

- Chromium denkt Display ist 400x1280 (Portrait)
- xrandr zeigt 1280x400 (Landscape)
- Chromium rendert für 400x1280, aber Display zeigt 1280x400
- → Bild ist abgeschnitten/verschoben

## Erwartetes Ergebnis:

- ✅ Chromium Window-Size = 1280x400
- ✅ xrandr = 1280x400
- ✅ Beide konsistent → Bild vollständig!

---

**Status:** ✅ Chromium Window-Size korrigiert! Bild sollte vollständig sein!

