# Video Parameter in cmdline.txt

## Durchgeführte Änderungen:

1. ✅ **Backup erstellt:** `cmdline.txt.video_backup`
2. ✅ **video Parameter hinzugefügt:** `video=HDMI-A-1:1280x400@60`
3. ✅ **Reboot durchgeführt**

## Video Parameter Syntax:

- `video=HDMI-A-1:1280x400@60` - HDMI-A-1, 1280x400, 60Hz
- `video=HDMI-A-1:1280x400@60,rotate=90` - Mit Rotation (falls benötigt)

## Erwartetes Ergebnis:

- ✅ Display wird mit 1280x400@60Hz initialisiert
- ✅ Direkt über Kernel-Parameter
- ✅ Funktioniert mit KMS

## Alternative Optionen:

- `video=HDMI-A-1:1280x400@60,rotate=90` - Portrait mit Rotation
- `video=HDMI-A-1:1280x400@60M` - Mit Margins
- `video=HDMI-A-1:1280x400@60,overscan=0` - Ohne Overscan

---

**Status:** ✅ Video Parameter gesetzt! Reboot durchgeführt!

