# GOODIX POLLING MODE LÖSUNG

**Datum:** 02.12.2025  
**Erkenntnis:** WaveShare 7-inch Panels benötigen Polling Mode!

---

## WICHTIGE ERKENNTNISSE AUS ONLINE-RECHERCHE

### **1. Polling Mode Problem:**
- **WaveShare 7-inch Panels (GT911) haben KEINE Interrupt-Pins!**
- Der `ws_touchscreen` Driver versucht Interrupt-Mode zu verwenden
- **Lösung:** Polling Mode aktivieren

### **2. Bekannte Probleme:**
- I2C Write Error -5 ist bekannt bei Goodix ohne Interrupt-Pins
- Patch verfügbar: https://lkml.org/lkml/2025/5/21/484
- Custom Device Tree Overlay nötig

### **3. Driver-Kompatibilität:**
- `ws_touchscreen` (WaveShare) vs `goodix_ts` (Linux Kernel)
- `goodix_ts` mit Polling Mode Patch funktioniert besser

---

## LÖSUNGSANSATZ

### **1. Goodix Polling Mode Overlay:**
- Custom Device Tree Overlay erstellt
- Ohne Interrupt-Pins konfiguriert
- Polling Mode aktiviert

### **2. Config.txt Anpassung:**
- `dtoverlay=goodix-polling` hinzugefügt
- Nach `vc4-kms-dsi-waveshare-panel`

### **3. Kernel Patch:**
- Polling Mode Patch für Goodix Driver
- Falls Kernel-Patch nötig ist

---

## IMPLEMENTIERUNG

### **Durchgeführt:**
- ✅ Goodix Polling Mode Overlay erstellt
- ✅ Overlay kompiliert
- ✅ Config.txt angepasst
- ⏳ Reboot nötig

---

## ERWARTETE ERGEBNISSE

### **Nach Reboot:**
- ✅ Goodix Driver lädt mit Polling Mode
- ✅ Keine I2C Write Errors mehr
- ✅ Input Device wird erstellt
- ✅ Touchscreen funktioniert

---

**Lösung basierend auf Online-Recherche implementiert...**

