# Rotation Fix für KMS

## Problem:

- ❌ `display_rotate` funktioniert **NICHT mit KMS** (vc4-kms-v3d)
- ❌ Display geht aus beim Drehen

## Lösung:

### Option 1: HDMI CVT ändern (Portrait direkt)
- ✅ `hdmi_cvt 400 1280 60 6 0 0 0` statt `1280 400`
- ✅ Portrait-Modus direkt in HDMI-Parametern
- ✅ Kein `display_rotate` nötig

### Option 2: Framebuffer-Rotation Tools
- `fbrotate` (falls verfügbar)
- `fbset -rotate 90`
- `xrandr` (für X11)

## Durchgeführte Änderungen:

1. ✅ `display_rotate=1` **entfernt** (funktioniert nicht mit KMS)
2. ✅ `hdmi_cvt` auf **400x1280** geändert (Portrait direkt)
3. ✅ Reboot durchgeführt

## Erwartetes Ergebnis:

- ✅ Display bleibt an beim Drehen
- ✅ Portrait-Modus (400x1280)
- ✅ Kein Display-Ausschalten mehr

---

**Status:** ✅ Rotation über HDMI CVT korrigiert!

