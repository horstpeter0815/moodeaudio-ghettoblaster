# I2C KABEL-DOKUMENTATION

**Datum:** 02.12.2025  
**Hardware:** DSP Add-on → AMP100 (SDA/SCL Kabel)

---

## HARDWARE-VERBINDUNGEN

### **DSP Add-on zu AMP100:**
- **2 Kabel:** SDA und SCL
- **Verbindung:** DSP Add-on → AMP100 (PCM5122)

### **I2C Bus 1 (Raspberry Pi 4):**
- **GPIO 2 (Pin 3):** SDA (Data)
- **GPIO 3 (Pin 5):** SCL (Clock)

### **Devices auf I2C Bus 1:**
- **AMP100 PCM5122:** Adresse 0x4d
- **Touchscreen FT6236:** Adresse 0x38

---

## PROBLEM

### **I2C Read/Write Error:**
- AMP100: I2C Read schlägt fehl
- Touchscreen: I2C Read schlägt fehl
- "Device or resource busy" beim manuellen Create

### **Mögliche Ursachen:**
1. **Kabel-Problem:**
   - SDA/SCL Kabel falsch verbunden
   - Kabel defekt
   - Lose Verbindung

2. **I2C Bus-Konflikt:**
   - Beide Devices auf gleichem Bus
   - Timing-Problem

3. **Power-Supply:**
   - 27W Pi 5 Netzteil für Pi 4 + AMP100
   - Möglicherweise unzureichend

---

## LÖSUNG

### **1. Kabel prüfen:**
- SDA/SCL Kabel vom DSP Add-on zum AMP100
- Verbindung prüfen
- Kabel ersetzen falls nötig

### **2. Hardware-Verbindung dokumentieren:**
- Welche Kabel wo verbunden
- Pin-Mapping

---

**Hardware-Analyse und Kabel-Prüfung in Arbeit...**

