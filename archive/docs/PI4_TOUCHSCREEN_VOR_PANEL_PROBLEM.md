# PI 4 TOUCHSCREEN VOR PANEL PROBLEM

**Datum:** 02.12.2025  
**Problem:** Touchscreen initialisiert vor Panel (wie ursprünglich)

**Lösung:** Ansatz 1 - Overlay deaktivieren, Service lädt Touchscreen nach Display

---

## ✅ GELÖST

### **1. Touchscreen Overlay deaktiviert:**
- ✅ `dtoverlay=ft6236` aus `config.txt` entfernt
- ✅ Touchscreen wird nicht mehr beim Boot geladen

### **2. Service angepasst:**
- ✅ `ft6236-delay.service` lädt Touchscreen **nach** `localdisplay.service`
- ✅ Verwendet `edt_ft5x06` Modul
- ✅ Kalibrierung wird automatisch gesetzt

---

## 🔧 KONFIGURATION

### **Config.txt:**
- `#dtoverlay=ft6236` (deaktiviert)

### **Service:**
- `/etc/systemd/system/ft6236-delay.service`
- `After=localdisplay.service`
- `ExecStart`: `sleep 5 && modprobe edt_ft5x06`

---

**Touchscreen sollte jetzt nach dem Display initialisiert werden!**

