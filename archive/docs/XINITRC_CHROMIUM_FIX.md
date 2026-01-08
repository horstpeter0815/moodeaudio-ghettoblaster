# xinitrc Chromium Window-Size Fix

## Problem:

- ❌ **Chromium in xinitrc:** `--window-size=400,1280` (Portrait)
- ❌ **xrandr:** `1280x400` (Landscape)
- ❌ **KONFLIKT!** → Bild abgeschnitten

## Lösung:

1. ✅ **xinitrc korrigiert:** `--window-size=1280,400`
2. ✅ **localdisplay.service neu gestartet**
3. ✅ **Chromium startet mit korrekter Window-Size**

## Erwartetes Ergebnis:

- ✅ Chromium Window-Size = 1280x400
- ✅ xrandr = 1280x400
- ✅ Beide konsistent → Bild vollständig!

---

**Status:** ✅ xinitrc korrigiert! Service neu gestartet!

