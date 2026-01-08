# PI 1 (Pi 4 - RaspiOS) VOLLSTÄNDIGES SETUP

**Datum:** 02.12.2025  
**IP:** 192.168.178.96  
**OS:** RaspiOS (Debian 13)

---

## ✅ IMPLEMENTIERT

### **1. Ansatz 1:**
- ✅ `ft6236-delay.service` aktiviert
- ✅ Verwendet `edt-ft5x06` Modul
- ✅ Startet nach `multi-user.target`

### **2. Display:**
- ✅ `localdisplay.service` aktiv
- ✅ X Server läuft
- ✅ Display-Rotation: Landscape (1280x400)

### **3. Touchscreen:**
- ✅ `edt-ft5x06` Modul geladen
- ✅ Touchscreen Devices vorhanden
- ✅ Kalibrierung gesetzt
- ✅ Xorg Config erstellt

### **4. PeppyMeter:**
- ✅ PeppyMeter installiert
- ✅ PeppyMeter Service erstellt
- ✅ Service aktiviert

### **5. MPD:**
- ✅ MPD aktiv

---

## 🔧 KONFIGURATION

### **Display:**
- Rotation: Landscape (left)
- Auflösung: 1280x400
- Service: `localdisplay.service`

### **Touchscreen:**
- Modul: `edt-ft5x06`
- Kalibrierung: Coordinate Transformation Matrix
- Xorg Config: `/etc/X11/xorg.conf.d/99-touchscreen.conf`

### **PeppyMeter:**
- Service: `/etc/systemd/system/peppymeter.service`
- Config: `/etc/peppymeter/config.txt`
- Fenster-Position: 0,0 (automatisch)

---

**PI 1 sollte jetzt vollständig funktionieren wie PI 2!**

