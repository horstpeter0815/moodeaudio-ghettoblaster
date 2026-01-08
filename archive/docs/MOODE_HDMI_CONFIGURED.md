# Moode Web-UI HDMI konfiguriert

## Durchgeführte Moode-Einstellungen:

1. ✅ **local_display=0** (HDMI verwenden, nicht DSI)
2. ✅ **dsi_scn_type='none'** (DSI deaktiviert)
3. ✅ **hdmi_scn_orient='landscape'** (HDMI Orientation)

## Config-Zusammenfassung:

### Hardware (config.txt):
- ✅ `hdmi_group=2`
- ✅ `hdmi_mode=87`
- ✅ `hdmi_cvt 1280 400 60 6 0 0 0`
- ✅ `display_rotate=1` (90° Portrait)
- ✅ `hdmi_force_hotplug=1`

### Moode Web-UI:
- ✅ `local_display=0` (HDMI)
- ✅ `dsi_scn_type='none'` (DSI aus)
- ✅ `hdmi_scn_orient='landscape'`

## Erwartetes Ergebnis:

- ✅ Moode Audio sollte auf HDMI-Display angezeigt werden
- ✅ 1280x400 Auflösung
- ✅ Portrait-Modus mit Rotation
- ✅ Web-UI zeigt HDMI als Display

---

**Status:** ✅ Moode Web-UI für HDMI konfiguriert!

