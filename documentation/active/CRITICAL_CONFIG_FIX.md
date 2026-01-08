# KRITISCHER CONFIG-FIX

## Problem gefunden!

`disable_fw_kms_setup=1` war gesetzt!

Das bedeutet:
- ❌ FKMS verwendet die Firmware NICHT für Display-Erkennung
- ❌ Firmware wird nicht nach Displays gefragt
- ❌ FKMS erstellt keine CRTCs basierend auf Firmware-Info

## Lösung

1. ✅ `disable_fw_kms_setup=0` gesetzt
2. ✅ `display_auto_detect=1` bereits gesetzt
3. ⏳ **REBOOT ERFORDERLICH**

## Theorie

Mit `disable_fw_kms_setup=0`:
- FKMS fragt die Firmware nach Displays
- Firmware sollte DSI-Display melden (wenn korrekt konfiguriert)
- FKMS erstellt CRTC für DSI automatisch

## Nach Reboot prüfen

```bash
# Prüfe ob Firmware Displays meldet
dmesg | grep -iE 'num_displays|display.*found|display.*id'

# Prüfe ob CRTC erstellt wurde
dmesg | grep -iE 'bogus.*possible_crtcs|creating.*crtc'

# Prüfe DSI-1 Status
cat /sys/class/drm/card1-DSI-1/enabled

# Prüfe ob LED noch blinkt
# (LED sollte NICHT mehr blinken wenn Display Daten erhält)
```

**Erwartetes Ergebnis:**
- ✅ Firmware meldet DSI-Display
- ✅ FKMS erstellt CRTC automatisch
- ✅ DSI-1 wird enabled
- ✅ LED blinkt NICHT mehr

---

**Status:** KRITISCHER FIX angewendet! **REBOOT ERFORDERLICH!**

