# Pi 5 HDMI Config bereit

## Config für Pi 5 HDMI Waveshare:

### Pi 5 spezifische Einstellungen:
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
- ✅ `display_rotate=1` (90° Portrait)

## Wichtig:

- ✅ **Pi 5 Config** (`PI5_WORKING_CONFIG.txt`)
- ✅ **Pi 5 KMS** (`vc4-kms-v3d-pi5`, nicht generisch!)
- ✅ **HDMI statt DSI**

---

**Status:** ⏳ Warte auf Pi 5 Online...

