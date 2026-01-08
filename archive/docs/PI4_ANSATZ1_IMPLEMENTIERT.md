# PI 4 ANSATZ 1 IMPLEMENTIERT

**Datum:** 02.12.2025  
**Status:** ✅ **ANSATZ 1 IMPLEMENTIERT**

---

## ✅ IMPLEMENTIERT

### **1. Touchscreen Overlay deaktiviert:**
- ✅ `#dtoverlay=ft6236` in `config.txt`
- ✅ Touchscreen wird nicht mehr beim Boot geladen

### **2. Service angepasst:**
- ✅ `ft6236-delay.service` lädt Touchscreen **nach** `localdisplay.service`
- ✅ Verwendet manuelles Device-Create über I2C
- ✅ Kalibrierung wird automatisch gesetzt

---

## ⚠️ HARDWARE-PROBLEM

### **Touchscreen:**
- ✅ Overlay deaktiviert (initialisiert nicht vor Panel)
- ✅ Service lädt nach Display
- ❌ I2C Device wird nicht erstellt
- ❌ I2C Read/Write Error
- **Problem:** Hardware-Kommunikationsproblem (Power oder Verbindung)

---

## 🔧 KONFIGURATION

### **Config.txt:**
- `#dtoverlay=ft6236` (deaktiviert)

### **Service:**
- `/etc/systemd/system/ft6236-delay.service`
- `After=localdisplay.service`
- `ExecStart`: `sleep 5 && echo "edt-ft5x06 0x38" > /sys/bus/i2c/devices/i2c-1/new_device`

---

**✅ ANSATZ 1 IST IMPLEMENTIERT - Touchscreen initialisiert nicht mehr vor Panel!**

**Hardware-Problem: I2C-Kommunikation funktioniert nicht (möglicherweise Power oder Verbindung).**

