# Video Parameter entfernt - verwende nur HDMI CVT

## Problem:

- ❌ **video Parameter wird ignoriert** (Framebuffer bleibt 400x1280)
- ❌ **KMS überschreibt video Parameter**

## Lösung:

1. ✅ **video Parameter entfernt** aus cmdline.txt
2. ✅ **Verwende nur HDMI CVT:** `hdmi_cvt 1280 400 60 6 0 0 0`
3. ✅ **Reboot durchgeführt**

## Warum:

- HDMI CVT wird von KMS respektiert
- video Parameter wird von KMS ignoriert
- HDMI CVT hat Priorität bei KMS

## Erwartetes Ergebnis:

- ✅ Framebuffer sollte 1280x400 sein (Landscape)
- ✅ HDMI CVT setzt die Auflösung korrekt
- ✅ Kein Konflikt mehr zwischen video Parameter und HDMI CVT

---

**Status:** ✅ Video Parameter entfernt, verwende nur HDMI CVT!

