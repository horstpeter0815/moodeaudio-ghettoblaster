# HDMI Deployment Status

## Situation:

- ⏳ **Pi ist nicht erreichbar** (möglicherweise ausgeschaltet oder bootet)
- ✅ **Config ist vorbereitet** (`config_optimal_waveshare.txt`)

## Vorbereitete Config:

- ✅ DSI Overlay deaktiviert
- ✅ HDMI aktiviert (`hdmi_force_hotplug=1`)
- ✅ HDMI-Parameter für 1280x400:
  - `hdmi_group=2`
  - `hdmi_mode=87`
  - `hdmi_cvt 1280 400 60 6 0 0 0`
  - `hdmi_drive=2`

## Nächste Schritte:

1. ⏳ **Pi einschalten** (falls ausgeschaltet)
2. ⏳ **Warte auf SSH-Verbindung**
3. ⏳ **Config übertragen**
4. ⏳ **Reboot durchführen**

## Alternative:

Falls der Pi physisch verfügbar ist, kann die Config auch direkt auf die SD-Karte kopiert werden:
- `/boot/firmware/config.txt` auf der SD-Karte ersetzen

---

**Status:** ⏳ Warte auf Pi-Verfügbarkeit...

