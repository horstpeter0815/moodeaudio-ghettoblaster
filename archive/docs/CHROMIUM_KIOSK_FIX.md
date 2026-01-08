# CHROMIUM KIOSK-MODUS FIX

**Problem:** Chromium-Fenster kann mit Fingern verschoben werden

**Lösung:** Chromium im echten Kiosk-Modus mit festen Fenster-Parametern starten

---

## ✅ IMPLEMENTIERT

1. **Chromium Service erstellt:**
   - `/etc/systemd/system/chromium-kiosk.service`
   - Startet nach `localdisplay.service`
   - Verwendet `--kiosk` Flag
   - Fenster-Position: `--window-position=0,0`
   - Fenster-Größe: `--window-size=1280,400`
   - URL: `http://localhost:8080` (PeppyMeter)

2. **Service aktiviert:**
   - Automatischer Start nach Reboot
   - Restart bei Fehler

---

## 🔧 PARAMETER

- `--kiosk`: Vollbild-Modus, keine UI-Elemente
- `--window-position=0,0`: Fenster an Position 0,0 fixieren
- `--window-size=1280,400`: Fenster-Größe festlegen
- `--noerrdialogs`: Keine Fehler-Dialoge
- `--disable-infobars`: Keine Info-Bars
- `--app=http://localhost:8080`: App-Modus (keine Adressleiste)

---

**Fenster sollte jetzt nicht mehr verschiebbar sein!**

