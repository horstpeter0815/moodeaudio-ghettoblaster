# Patch aus Kernel-Sources kompiliert

## Durchgeführte Aktionen

1. ✅ `linux-source-6.12` installiert
2. ✅ Sources extrahiert
3. ✅ Gepatchte `vc4_firmware_kms.c` in Sources eingefügt
4. ✅ Modul aus Sources kompiliert
5. ✅ Kompiliertes Modul installiert
6. ⏳ **REBOOT ERFORDERLICH**

## Patch-Details

Der Patch erstellt proaktiv einen CRTC für DSI (display_num 0), auch wenn die Firmware kein DSI-Display meldet.

## Nach Reboot prüfen

```bash
# Prüfe ob Patch aktiv ist
dmesg | grep -iE 'proactive|creating.*crtc|successfully.*crtc'

# Prüfe DSI-1 Status
cat /sys/class/drm/card1-DSI-1/enabled

# Prüfe xrandr
xrandr | grep DSI-1

# Prüfe ob LED noch blinkt
# (LED sollte NICHT mehr blinken wenn Display Daten erhält)
```

**Erwartetes Ergebnis:**
- ✅ dmesg: "Creating proactive CRTC for DSI" oder "Successfully created proactive CRTC"
- ✅ /sys/class/drm/card1-DSI-1/enabled: "enabled"
- ✅ xrandr: DSI-1 aktivierbar
- ✅ LED: blinkt NICHT mehr (Display erhält Daten)

---

**Status:** Patch kompiliert und installiert. **REBOOT ERFORDERLICH!**

