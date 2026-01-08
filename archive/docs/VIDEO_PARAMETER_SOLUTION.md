# Video Parameter Lösung

## Problem:

- ❌ **fbset funktioniert NICHT mit KMS/DRM** (`ioctl FBIOPUT_VSCREENINFO: Invalid argument`)
- ✅ **Lösung: video Parameter in cmdline.txt**

## Aktive Lösung:

### cmdline.txt:
- ✅ `video=HDMI-A-1:1280x400@60` - Setzt Display-Mode direkt über Kernel

### Warum fbset nicht funktioniert:
- KMS/DRM verwaltet den Framebuffer
- fbset kann KMS-Framebuffer nicht direkt ändern
- Video Parameter wird früher geladen (Kernel-Level)

## Config:

- ✅ **cmdline.txt:** `video=HDMI-A-1:1280x400@60`
- ✅ **config.txt:** `hdmi_cvt 1280 400 60 6 0 0 0`
- ✅ **fbset Service entfernt** (funktioniert nicht mit KMS)

## Erwartetes Ergebnis:

- ✅ Display wird mit 1280x400@60Hz initialisiert
- ✅ Über Kernel video Parameter
- ✅ Funktioniert mit KMS/DRM

---

**Status:** ✅ Video Parameter ist die richtige Lösung für KMS!

