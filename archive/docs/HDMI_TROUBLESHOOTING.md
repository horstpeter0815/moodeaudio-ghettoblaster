# HDMI Troubleshooting

## Status nach Reboot:

- ⏳ Prüfe Display-Status
- ⏳ Prüfe Framebuffer
- ⏳ Prüfe HDMI-Erkennung
- ⏳ Prüfe dmesg für Fehler

## Mögliche Probleme:

1. **HDMI nicht erkannt**
   - Prüfe `vcgencmd get_display_power`
   - Prüfe HDMI-Kabel
   - Prüfe HDMI-Parameter

2. **Framebuffer nicht rotiert**
   - Prüfe `display_rotate=1` in config.txt
   - Prüfe Framebuffer-Größe

3. **Kein Bild**
   - Prüfe dmesg für Fehler
   - Prüfe HDMI-Mode
   - Prüfe KMS-Status

## Nächste Schritte:

- ⏳ Prüfe Status nach Boot
- ⏳ Analysiere Fehler
- ⏳ Korrigiere Config falls nötig

---

**Status:** ⏳ Troubleshooting läuft...

