# TOUCHSCREEN ROTATIONS-BUTTON

**Datum:** 03.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Aktion:** Rotations-Button am Display drücken

---

## 🔘 ROTATIONS-BUTTON

### **Hardware-Rotation:**
- Display hat einen **Rotations-Button** für den Touchscreen
- Rotiert den Touchscreen in Hardware
- Synchronisiert Touchscreen mit Display-Rotation

### **Display-Rotation:**
- Display: **270° rotiert** (Landscape)
- `display_rotate=3` in config.txt
- `transform=rotate-270` in weston.ini

### **Problem:**
- Touchscreen war möglicherweise **nicht rotiert**
- Display rotiert, Touchscreen nicht
- Koordinaten-Mapping falsch

---

## 🔧 LÖSUNG

### **1. Rotations-Button drücken:**
- Button am Display drücken
- Touchscreen wird in Hardware rotiert
- Synchronisiert mit Display-Rotation

### **2. Weston neu starten:**
```bash
systemctl restart weston.service
```

### **3. Touchscreen testen:**
- Touchscreen berühren
- Sollte jetzt funktionieren

---

## 📝 TOUCHSCREEN STATUS NACH ROTATION

### **Erwartetes Ergebnis:**
- ✅ Touchscreen rotiert (Hardware)
- ✅ Display rotiert (Software)
- ✅ Koordinaten-Mapping korrekt
- ✅ Touchscreen funktioniert

---

## ⚠️ HINWEISE

### **Hardware vs. Software Rotation:**
- **Hardware-Rotation:** Rotations-Button am Display
- **Software-Rotation:** `display_rotate=3`, `transform=rotate-270`
- Beide müssen synchronisiert sein

### **Falls Touchscreen immer noch nicht funktioniert:**
1. Rotations-Button mehrmals drücken (verschiedene Rotationen testen)
2. Weston neu starten
3. Events testen
4. Calibration prüfen

---

**Status:** ⏳ **ROTATIONS-BUTTON GEDRÜCKT - PRÜFUNG LÄUFT...**

