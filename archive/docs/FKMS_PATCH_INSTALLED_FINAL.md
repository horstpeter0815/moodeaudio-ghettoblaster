# FKMS Patch Installation - Abgeschlossen

## Durchgeführte Schritte

1. ✅ **Speicherplatz freigemacht** - /tmp/kernel-source gelöscht, apt clean
2. ✅ **Backup erstellt** - Original vc4_firmware_kms.c gesichert
3. ✅ **Patch angewendet** - V4 proaktiver CRTC-Patch in Datei eingefügt
4. ✅ **Modul kompiliert** - vc4_firmware_kms.ko erstellt
5. ✅ **Modul installiert** - Nach /lib/modules/.../kernel/drivers/gpu/drm/vc4/
6. ✅ **depmod ausgeführt** - Module-Dependencies aktualisiert
7. ✅ **Modul neu geladen** - modprobe -r dann modprobe
8. ✅ **System neu gestartet** - Reboot durchgeführt

## Patch-Details

**V4 Proaktiver Ansatz:**
- Erstellt IMMER einen CRTC für display_num 0 (DSI MAIN_LCD)
- Prüft ob bereits ein CRTC für display_num 0 existiert
- Falls nicht: Erstellt neuen CRTC und fügt ihn zur crtc_list hinzu
- Position: Nach Zeile 2011 in vc4_firmware_kms.c

## Nach Reboot zu prüfen

1. **dmesg** - Suche nach "Creating proactive CRTC" oder "Successfully created proactive CRTC"
2. **/sys/class/drm/card1-DSI-1/enabled** - Sollte "enabled" sein
3. **xrandr** - DSI-1 sollte CRTC haben und aktivierbar sein
4. **Display** - Sollte Bild zeigen

## Erwartetes Ergebnis

- DSI-1 sollte jetzt einen CRTC haben
- xrandr sollte DSI-1 aktivieren können
- Display sollte Bild zeigen
- Framebuffer sollte 1280x400 sein

---

**Status:** Patch installiert, System neu gestartet. Warte auf Boot und Test.

