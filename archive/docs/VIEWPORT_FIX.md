# Viewport Fix - Bild abgeschnitten

## Problem:

- ❌ **Bild ist rotiert, aber abgeschnitten**
- ❌ **Linke Seite und 2/3 rechts sind schwarz**
- ❌ **Viewport/Offset Problem bei Rotation**

## Mögliche Ursachen:

1. **Rotation verschiebt Viewport** - xrandr Rotation könnte Viewport falsch setzen
2. **Mode 1280x400 nicht verfügbar** - xrandr hat nur 400x1280 Mode
3. **Viewport/Panning falsch** - Display zeigt nur Teil des Bildes

## Lösung:

1. ✅ **Mode 1280x400 hinzugefügt** (falls nicht verfügbar)
2. ✅ **Mode direkt gesetzt** (ohne Rotation)
3. ✅ **Viewport korrigiert**

## Erwartetes Ergebnis:

- ✅ Bild ist vollständig sichtbar
- ✅ Keine schwarzen Bereiche
- ✅ 1280x400 Landscape korrekt

---

**Status:** ✅ Viewport korrigiert! Bild sollte vollständig sein!

