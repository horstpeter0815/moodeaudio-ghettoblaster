# HDMI Display Setup

## Situation:

- ✅ **HDMI-Version des Waveshare Displays** zeigt Login-Bildschirm
- ⏳ **Moode Audio auf HDMI umstellen**

## Durchgeführte Änderungen:

1. ✅ **local_display deaktiviert** (DSI)
2. ✅ **dsi_scn_type auf 'none'** gesetzt
3. ✅ **HDMI aktiviert** in config.txt:
   - `hdmi_ignore_hotplug=0` (HDMI wird erkannt)
   - `hdmi_force_hotplug=1` (HDMI wird erzwungen)
4. ✅ **Reboot durchgeführt**

## Erwartetes Ergebnis:

- ✅ HDMI wird erkannt
- ✅ Moode Audio zeigt auf HDMI-Display
- ✅ Login-Bildschirm sollte Moode UI zeigen

## Warum das hilft:

- ✅ Zeigt dass Display-Hardware funktioniert
- ✅ Zeigt dass Moode Audio Display-Ausgabe kann
- ✅ Hilft zu verstehen warum DSI nicht funktioniert

---

**Status:** HDMI aktiviert, Reboot durchgeführt. Prüfe ob Moode auf HDMI angezeigt wird...

