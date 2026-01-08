# HDMI Force Hotplug Fix

## Problem gefunden:

- ❌ **HDMI-A-1 ist "disconnected"** - Display wird nicht erkannt!
- ❌ **Framebuffer zeigt 400x1280** weil kein HDMI erkannt wird

## Lösung:

1. ✅ **hdmi_force_hotplug=1** gesetzt (erzwingt HDMI-Erkennung)
2. ✅ **hdmi_cvt entfernt** (Konflikt mit hdmi_timings)
3. ✅ **hdmi_timings aktiv** für 1280x400
4. ✅ **Reboot durchgeführt**

## Config:

- ✅ `hdmi_force_hotplug=1` - Erzwingt HDMI-Erkennung
- ✅ `hdmi_group=2`, `hdmi_mode=87`
- ✅ `hdmi_timings=1280 0 100 20 100 400 0 20 8 20 0 0 0 60 0 48000000 6`

## Erwartetes Ergebnis:

- ✅ HDMI sollte als "connected" erkannt werden
- ✅ Framebuffer sollte 1280x400 sein (Landscape)
- ✅ Display sollte funktionieren

---

**Status:** ✅ HDMI Force Hotplug gesetzt! Reboot durchgeführt!

