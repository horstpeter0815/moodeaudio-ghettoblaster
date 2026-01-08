# Pi 5 HDMI Config mit Rotation deployed

## Durchgeführte Aktionen:

1. ✅ **Pi 5 gefunden** (192.168.178.134)
2. ✅ **Backup erstellt** (`config.txt.hdmi_backup`)
3. ✅ **Pi 5 Config übertragen** (`PI5_WORKING_CONFIG.txt`)
4. ✅ **Framebuffer-Rotation gesetzt** (`display_rotate=1`)
5. ✅ **Reboot durchgeführt**

## Config-Zusammenfassung für Pi 5:

### Pi 5 KMS:
- ✅ `dtoverlay=vc4-kms-v3d-pi5,noaudio` (Pi 5 spezifisch!)
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

## Wichtig für Pi 5:

- ✅ **Pi 5 spezifisches KMS** (`vc4-kms-v3d-pi5`, nicht generisch!)
- ✅ HDMI statt DSI
- ✅ Rotation für Portrait-Modus

---

**Status:** ✅ Pi 5 HDMI Config mit Rotation deployed! Reboot durchgeführt!
