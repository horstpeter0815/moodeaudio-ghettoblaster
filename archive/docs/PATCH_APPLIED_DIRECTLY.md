# Patch direkt auf Pi angewendet

## Durchgeführte Aktionen

1. ✅ Gepatchte `vc4_firmware_kms.c` auf Pi übertragen
2. ✅ Original-Datei in Headers-Verzeichnis ersetzt
3. ✅ Modul direkt auf Pi kompiliert
4. ✅ Kompiliertes Modul installiert
5. ⏳ Reboot erforderlich

## Patch-Details

Der Patch fügt Code hinzu, der:
- Proaktiv einen CRTC für DSI erstellt (display_num 0)
- DSI-Encoder findet und CRTC zuweist
- "Creating proactive CRTC" in dmesg loggt

## Nach Reboot prüfen

```bash
dmesg | grep -iE 'proactive|creating.*crtc|successfully.*crtc'
cat /sys/class/drm/card1-DSI-1/enabled
xrandr | grep DSI-1
```

**Erwartetes Ergebnis:**
- dmesg: "Creating proactive CRTC for DSI" oder "Successfully created proactive CRTC"
- /sys/class/drm/card1-DSI-1/enabled: "enabled"
- xrandr: DSI-1 aktivierbar
- LED: blinkt nicht mehr (Display erhält Daten)

---

**Status:** Patch angewendet, Modul kompiliert und installiert. Reboot erforderlich.

