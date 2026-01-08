# HARDWARE KABEL-ANALYSE

**Datum:** 02.12.2025  
**Problem:** I2C-Kommunikation schlägt fehl - Kabel-Problem vermutet

---

## HARDWARE-VERBINDUNGEN

### **DSP Add-on zu AMP100:**
- **2 Kabel:** SDA und SCL
- **Verbindung:** DSP Add-on → AMP100 (PCM5122)
- **Status:** ⚠️ Muss geprüft werden

### **I2C Bus 1 (Raspberry Pi 4):**
- **GPIO 2 (Pin 3):** SDA (Data)
- **GPIO 3 (Pin 5):** SCL (Clock)
- **Devices:**
  - AMP100 PCM5122: Adresse 0x4d (✅ erkannt, Driver: pcm512x)
  - Touchscreen FT6236: Adresse 0x38 (❌ nicht erkannt)

---

## PROBLEM-ANALYSE

### **Aktueller Status:**
1. **AMP100:** ✅ Erkannt auf I2C Bus 1, Adresse 0x4d
   - Device existiert: `/sys/bus/i2c/devices/i2c-1/1-004d`
   - Driver gebunden: `pcm512x`
   - I2C Read/Write: "Device or resource busy" (normal, da Driver gebunden)

2. **Touchscreen:** ❌ Nicht erkannt auf I2C Bus 1, Adresse 0x38
   - Device existiert nicht: `/sys/bus/i2c/devices/i2c-1/1-0038`
   - Driver nicht gebunden
   - I2C Read/Write: Fehler

### **Mögliche Ursachen:**
1. **Kabel-Problem:**
   - SDA/SCL Kabel vom DSP Add-on zum AMP100 falsch verbunden
   - Kabel defekt
   - Lose Verbindung

2. **I2C Bus-Konflikt:**
   - Beide Devices auf gleichem Bus
   - Timing-Problem beim Boot

3. **Power-Supply:**
   - 27W Pi 5 Netzteil für Pi 4 + AMP100
   - Möglicherweise unzureichend

---

## LÖSUNGSANSÄTZE

### **1. Kabel prüfen:**
- **SDA/SCL Kabel vom DSP Add-on zum AMP100:**
  - Verbindung prüfen
  - Kabel ersetzen falls nötig
  - Auf einer Seite ersetzen (DSP Add-on oder AMP100)

### **2. Hardware-Verbindung dokumentieren:**
- Welche Kabel wo verbunden
- Pin-Mapping
- Kabel-Typ und Länge

### **3. I2C Bus trennen (falls nötig):**
- Touchscreen auf anderen Bus (falls möglich)
- Oder AMP100 auf anderen Bus

---

## NÄCHSTE SCHRITTE

1. ✅ Kabel-Verbindungen dokumentiert
2. ⏳ Kabel prüfen (Hardware)
3. ⏳ Kabel ersetzen falls nötig
4. ⏳ I2C-Kommunikation testen

---

**Hardware-Analyse im Projektplan integriert...**

