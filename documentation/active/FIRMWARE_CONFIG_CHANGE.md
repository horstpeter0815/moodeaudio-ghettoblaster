# Firmware-Config-Änderung

## Problem

Kernel-Modul-Patch kann nicht kompiliert werden:
- Fehlende Symbol-Definitionen
- Modul kann nicht als Standalone kompiliert werden
- Erfordert vollständigen Kernel-Build

## Alternative: Firmware-Parameter ändern

Versuch, die Firmware so zu konfigurieren, dass sie DSI-Display meldet:

1. ✅ `display_auto_detect=1` gesetzt
2. ✅ `ignore_lcd=0` gesetzt
3. ⏳ **REBOOT ERFORDERLICH**

## Theorie

Wenn die Firmware das DSI-Display meldet, sollte FKMS automatisch einen CRTC erstellen.

## Nach Reboot prüfen

```bash
# Prüfe ob Firmware DSI meldet
dmesg | grep -iE 'display|dsi|lcd'

# Prüfe DSI-1 Status
cat /sys/class/drm/card1-DSI-1/enabled

# Prüfe ob CRTC erstellt wurde
dmesg | grep -iE 'bogus.*possible_crtcs'
```

**Erwartetes Ergebnis:**
- ✅ Firmware meldet DSI-Display
- ✅ FKMS erstellt CRTC automatisch
- ✅ DSI-1 wird enabled
- ✅ LED blinkt NICHT mehr

---

**Status:** Config geändert. **REBOOT ERFORDERLICH!**

