# Boot-Screen Config aktualisiert

## Durchgeführte Änderungen:

1. ✅ **config_optimal_waveshare.txt**: `disable_splash=1` → `disable_splash=0`
2. ✅ **PI5_WORKING_CONFIG.txt**: `disable_splash=1` → `disable_splash=0`

## Erwartetes Ergebnis:

- ✅ Boot-Screen sollte auf Framebuffer angezeigt werden
- ✅ Splash-Screen wird während Boot sichtbar sein

## Wichtig:

- Diese Dateien sind lokale Backups
- Die Änderungen müssen auf den Pi übertragen werden:
  - `/boot/firmware/config.txt` auf dem Pi
  - `fbcon=map=1` in `/boot/firmware/cmdline.txt` (falls nicht vorhanden)

## Nächste Schritte:

1. ⏳ Config auf Pi übertragen
2. ⏳ `fbcon=map=1` in cmdline.txt setzen
3. ⏳ Reboot durchführen

---

**Status:** ✅ Lokale Config-Dateien aktualisiert!

