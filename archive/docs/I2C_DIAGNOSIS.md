# I2C DIAGNOSIS - HIFIBERRY AUDIO PROBLEM

**Date:** 2025-12-04  
**Problem:** I2C Controller Timeout - PCM512x kann nicht initialisiert werden

---

## 🔍 PROBLEM

### **Symptome:**
- ❌ `i2c_designware 1f00074000.i2c: controller timed out` (mehrfach)
- ❌ `pcm512x 1-004d: probe with driver pcm512x failed with error -110`
- ❌ Keine Soundkarten erkannt
- ❌ GPIO17 Reset nicht möglich (GPIO-Sysfs nicht verfügbar)

### **Root Cause:**
**I2C-Bus antwortet nicht** - Hardware-Kommunikation schlägt fehl

---

## 🔧 MÖGLICHE URSACHEN

### **1. Hardware-Verbindung:**
- HiFiBerry Board nicht richtig angeschlossen
- I2C-Kabel lose oder defekt
- Falsche Pins verwendet

### **2. I2C-Bus Problem:**
- Falscher I2C-Bus verwendet (Pi 5 hat mehrere)
- I2C-Bus defekt
- Konflikt mit anderen Geräten

### **3. Hardware-Kompatibilität:**
- HiFiBerry Board nicht Pi 5 kompatibel
- Power-Problem
- Board defekt

### **4. Software-Konfiguration:**
- Falsches Device Tree Overlay
- I2C-Treiber-Problem
- Timing-Problem

---

## 🛠️ LÖSUNGSANSÄTZE

### **Option 1: Hardware prüfen**
- Physische Verbindung prüfen
- I2C-Kabel testen
- Board auf anderen Pi testen

### **Option 2: I2C-Bus wechseln**
- Anderen I2C-Bus versuchen
- I2C-Bus-Konfiguration ändern

### **Option 3: Overlay wechseln**
- `hifiberry-amp100` statt `hifiberry-dacplus` versuchen
- Oder umgekehrt

### **Option 4: Hardware-Reset**
- Board physisch trennen
- Wieder anschließen
- Power-Cycle

---

## 📋 NÄCHSTE SCHRITTE

1. **Hardware-Verbindung prüfen:**
   - Ist das HiFiBerry Board richtig angeschlossen?
   - Sind die I2C-Pins korrekt?
   - Funktionierte es vorher?

2. **Welches HiFiBerry Board?**
   - AMP100?
   - DAC+ Pro?
   - Anderes?

3. **Hardware-Test:**
   - Board auf Pi 4 testen (funktioniert dort)
   - Board auf Pi 5 testen

---

**Status:** I2C-Timeout - Hardware-Problem oder Verbindungsproblem

