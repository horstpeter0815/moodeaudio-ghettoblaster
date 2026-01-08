# TOUCHSCREEN PROBLEM ANALYSE

**Datum:** 03.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Status:** ⚠️ **TOUCHSCREEN ERKANNT, ABER FUNKTIONIERT NICHT**

---

## 🔍 PROBLEM

### **Touchscreen wird erkannt:**
- ✅ USB Device: WaveShare (0712:000a)
- ✅ Input Device: `/dev/input/event6`
- ✅ libinput: Touchscreen erkannt
- ✅ Weston: Läuft
- ❌ **Touchscreen funktioniert nicht in Apps**

---

## 🔧 DURCHGEFÜHRTE MASSNAHMEN

### **1. require-input aktiviert:**
```ini
[core]
require-input=true  # Geändert von false
```

### **2. Weston neu gestartet:**
```bash
systemctl restart weston.service
```

### **3. Status:**
- Weston läuft mit `--continue-without-input` (Service-Definition)
- libinput erkennt Touchscreen
- Keine Events beim Test empfangen

---

## 🔍 MÖGLICHE URSACHEN

### **1. Touchscreen sendet keine Events:**
- Hardware-Problem
- USB-Kabel-Problem
- Touchscreen defekt

### **2. Events werden nicht an Weston weitergegeben:**
- libinput → Weston Integration-Problem
- Weston verwendet Touchscreen nicht
- Coordinate-Mapping-Problem

### **3. Calibration-Problem:**
- Touchscreen-Koordinaten passen nicht zur Display-Rotation
- Display: 1280x400px, Rotation: 270°
- Touchscreen: 512x293mm
- Calibration: identity matrix (Standard)

### **4. Rotation-Problem:**
- Touchscreen-Koordinaten nicht rotiert
- Display rotiert, Touchscreen nicht
- Koordinaten-Mapping falsch

---

## 🔧 NÄCHSTE SCHRITTE

### **1. Events direkt testen:**
```bash
# Events vom Touchscreen lesen
hexdump -C /dev/input/event6

# Falls keine Events: Touchscreen sendet keine Daten
# Falls Events: Touchscreen funktioniert, aber Weston-Problem
```

### **2. Weston libinput Integration prüfen:**
```bash
# Prüfe ob Weston libinput verwendet
export XDG_RUNTIME_DIR=/var/run/weston
WAYLAND_DISPLAY=wayland-0 weston-info
```

### **3. Calibration prüfen:**
- Touchscreen-Koordinaten-Mapping
- Rotation-Koordinaten
- Display-Koordinaten

### **4. Alternative: X11-Test:**
- Falls X11 verfügbar: X11-Test
- Prüfe ob Touchscreen in X11 funktioniert

---

## 📝 TOUCHSCREEN DETAILS

### **USB Device:**
```
Bus 001 Device 005: ID 0712:000a WaveShare WaveShare
```

### **Input Device:**
```
/dev/input/event6
Name: "WaveShare WaveShare"
Size: 512x293mm
Capabilities: touch
Calibration: identity matrix
```

### **Display:**
```
Resolution: 1280x400px
Rotation: 270° (rotate-270)
Mode: 400x1280@60
```

---

## ⚠️ HINWEISE

### **Weston Service:**
- Weston läuft mit `--continue-without-input`
- Dies bedeutet: Weston startet auch ohne Input-Devices
- Sollte Touchscreen trotzdem verwenden, wenn vorhanden

### **libinput:**
- Touchscreen wird von libinput erkannt
- Calibration: identity matrix (Standard)
- Möglicherweise Calibration-Problem

---

**Status:** ⚠️ **PROBLEM ANALYSIERT - WEITERE TESTS NÖTIG**

