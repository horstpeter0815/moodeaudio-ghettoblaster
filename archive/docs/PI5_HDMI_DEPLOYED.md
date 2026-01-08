# Pi 5 HDMI Config deployed

## Durchgeführte Aktionen:

1. ✅ **Pi 5 gefunden** (192.168.178.178)
2. ✅ **Backup erstellt** (`config.txt.hdmi_backup`)
3. ✅ **Pi 5 HDMI Config übertragen** (`PI5_WORKING_CONFIG.txt`)
4. ✅ **Framebuffer-Rotation gesetzt** (`display_rotate=1`)
5. ✅ **Reboot durchgeführt**

## Config-Zusammenfassung für Pi 5:

### Pi 5 spezifische KMS:
- ✅ `dtoverlay=vc4-kms-v3d-pi5,noaudio` (Pi 5 KMS!)
- ✅ `dtoverlay=vc4-kms-v3d` (Basis-KMS)

### HDMI-Einstellungen:
- ✅ DSI Overlay deaktiviert
- ✅ HDMI aktiviert (`hdmi_force_hotplug=1`)
- ✅ HDMI-Parameter für 1280x400:
  - `hdmi_group=2`
  - `hdmi_mode=87`
  - `hdmi_cvt 1280 400 60 6 0 0 0`
  - `hdmi_drive=2`

### Framebuffer-Rotation:
- ✅ `display_rotate=1` (90° Rotation für Portrait-Modus)

## Erwartetes Ergebnis:

- ✅ HDMI-Display sollte erkannt werden
- ✅ Auflösung 1280x400 (Portrait)
- ✅ Framebuffer rotiert (90°)
- ✅ Boot-Screen sollte sichtbar sein
- ✅ Moode Audio sollte auf HDMI angezeigt werden

---

**Status:** ✅ Pi 5 HDMI Config mit Rotation deployed! Reboot durchgeführt!

