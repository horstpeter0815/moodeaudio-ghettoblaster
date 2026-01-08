# Panning Fix - Bild abgeschnitten

## Problem gefunden:

- ❌ **Panning ist falsch:** `panning 1280x0+0+0` (Höhe = 0!)
- ❌ **Rotation verursacht Panning-Problem**
- ❌ **Bild ist abgeschnitten** (linke Seite und 2/3 rechts schwarz)

## Lösung:

1. ✅ **Panning korrigiert:** `--panning 1280x400+0+0`
2. ✅ **Rotation entfernt:** Verwende nur Mode 1280x400 direkt
3. ✅ **xinitrc korrigiert:** Keine Rotation mehr, nur Mode + Panning

## Warum Rotation entfernen:

- Rotation verursacht Panning-Problem
- Video Parameter setzt bereits 1280x400
- Keine Rotation nötig wenn Mode direkt 1280x400 ist

## Erwartetes Ergebnis:

- ✅ Bild ist vollständig sichtbar
- ✅ Keine schwarzen Bereiche
- ✅ 1280x400 Landscape korrekt

---

**Status:** ✅ Panning korrigiert! Bild sollte vollständig sein!

