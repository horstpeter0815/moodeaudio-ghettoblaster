# Troubleshooting Fixes

## Probleme gefunden:

1. **ws_touchscreen bindet an 0x45** (Panel-Adresse) → I2C Fehler -121
2. **CRTC-Problem:** "Cannot find any crtc or sizes"
3. **Backlight:** Möglicherweise zu niedrig oder aus

## Fixes durchgeführt:

1. ✅ **ws_touchscreen entfernt** (manuell)
2. ✅ **disable_touch zu config.txt hinzugefügt** (permanent)
3. ⏳ **Backlight prüfen und setzen**
4. ⏳ **Display-Test durchführen**

## Nächste Schritte:

1. Reboot mit disable_touch
2. Prüfe ob I2C Fehler weg sind
3. Prüfe ob Display funktioniert
4. Prüfe Backlight

---

**Status:** Fixes angewendet, teste jetzt...

