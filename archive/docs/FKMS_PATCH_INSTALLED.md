# FKMS Patch Installation - Abgeschlossen

## Durchgeführte Schritte

1. ✅ **Gepatchte Datei kopiert** - `vc4_firmware_kms.c` mit V4 Patch
2. ✅ **Backup erstellt** - Original-Modul gesichert
3. ✅ **Datei ersetzt** - In `/usr/src/linux-headers-6.12.47+rpt-rpi-v8/drivers/gpu/drm/vc4/`
4. ✅ **Modul kompiliert** - `vc4_firmware_kms.ko` erstellt
5. ✅ **Modul installiert** - Nach `/lib/modules/.../kernel/drivers/gpu/drm/vc4/`
6. ✅ **depmod ausgeführt** - Module-Dependencies aktualisiert
7. ✅ **Modul neu geladen** - `modprobe -r` dann `modprobe`

## Patch-Details

**V4 Proaktiver Ansatz:**
- Erstellt IMMER einen CRTC für display_num 0 (DSI MAIN_LCD)
- Prüft ob bereits ein CRTC für display_num 0 existiert
- Falls nicht: Erstellt neuen CRTC und fügt ihn zur crtc_list hinzu

## Nächste Schritte

1. Prüfe dmesg für "Creating proactive CRTC" Meldung
2. Prüfe `/sys/class/drm/card1-DSI-1/enabled` (sollte "enabled" sein)
3. Teste xrandr ob CRTC jetzt verfügbar ist
4. Teste ob Display Bild zeigt

---

**Status:** Patch installiert, warte auf Test-Ergebnis

