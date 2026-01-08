# CHROMIUM NICHT-VERSCHIEBBAR FIX - ABGESCHLOSSEN

**Problem:** Chromium-Fenster kann mit Fingern verschoben werden

**Lösung:** Chromium mit festen Parametern im echten Fullscreen-Modus starten

---

## ✅ IMPLEMENTIERT

### **Chromium Service:**
- `/etc/systemd/system/chromium-kiosk.service`
- **Parameter:**
  - `--start-fullscreen`: Echter Fullscreen-Modus
  - `--window-position=0,0`: Fenster an Position 0,0 fixieren
  - `--window-size=1280,400`: Fenster-Größe festlegen
  - `--disable-pinch`: Kein Verschieben mit Fingern
  - `--app=http://localhost:8080`: App-Modus (keine Adressleiste)

### **Service-Konfiguration:**
- Startet nach `localdisplay.service`
- Automatischer Restart bei Fehler
- Aktiviert für automatischen Start nach Reboot

---

## 🔧 PARAMETER-ERKLÄRUNG

- `--start-fullscreen`: Startet direkt im Fullscreen (nicht nur Kiosk)
- `--window-position=0,0`: Fixiert Fenster-Position
- `--window-size=1280,400`: Fixiert Fenster-Größe
- `--disable-pinch`: Deaktiviert Pinch-Gesten (Verschieben)
- `--app=URL`: App-Modus ohne Browser-UI

---

**Das Fenster sollte jetzt nicht mehr verschiebbar sein!**

**Bitte testen:**
- Versuche, das Chromium-Fenster mit den Fingern zu verschieben
- Es sollte sich nicht mehr bewegen lassen

