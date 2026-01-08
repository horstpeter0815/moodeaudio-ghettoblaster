# CHROMIUM NICHT VERSCHIEBBAR FIX

**Problem:** Chromium-Fenster kann mit Fingern verschoben werden

**Lösung:** 
1. Chromium mit `--disable-pinch` starten
2. Fenster-Position und -Größe festlegen
3. Touchscreen-Eigenschaften anpassen

---

## ✅ IMPLEMENTIERT

### **1. Chromium Service:**
- `/etc/systemd/system/chromium-kiosk.service`
- Parameter:
  - `--kiosk`: Vollbild-Modus
  - `--window-position=0,0`: Fenster an Position 0,0
  - `--window-size=1280,400`: Fenster-Größe festlegen
  - `--disable-pinch`: Kein Verschieben mit Fingern
  - `--app=http://localhost:8080`: App-Modus

### **2. Touchscreen-Konfiguration:**
- Kalibrierung gesetzt
- Send Events Mode angepasst

---

## 🔧 PARAMETER

**Chromium:**
- `--kiosk`: Vollbild, keine UI
- `--window-position=0,0`: Position fixieren
- `--window-size=1280,400`: Größe fixieren
- `--disable-pinch`: Kein Verschieben
- `--app=http://localhost:8080`: App-Modus

---

**Fenster sollte jetzt nicht mehr verschiebbar sein!**

