# HDMI Timings Lösung

## Problem:

- ❌ **Framebuffer bleibt 400x1280** (Portrait)
- ❌ **HDMI CVT wird ignoriert oder überschrieben**

## Neue Lösung:

1. ✅ **hdmi_cvt entfernt**
2. ✅ **hdmi_timings hinzugefügt:** `hdmi_timings=1280 0 100 20 100 400 0 20 8 20 0 0 0 60 0 48000000 6`
3. ✅ **Reboot durchgeführt**

## HDMI Timings Parameter:

- `1280` - Horizontale Auflösung
- `400` - Vertikale Auflösung
- `60` - Refresh Rate
- `48000000` - Pixel Clock

## Warum hdmi_timings:

- Direkter als hdmi_cvt
- Wird von KMS respektiert
- Force Mode für custom Auflösung

## Erwartetes Ergebnis:

- ✅ Framebuffer sollte 1280x400 sein (Landscape)
- ✅ HDMI timings setzt die Auflösung korrekt

---

**Status:** ✅ HDMI Timings gesetzt! Reboot durchgeführt!

