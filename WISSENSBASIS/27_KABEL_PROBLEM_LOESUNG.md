# KABEL-PROBLEM LÖSUNG

**Datum:** 02.12.2025  
**Status:** In Arbeit  
**Problem:** I2C-Kommunikation schlägt fehl - Kabel-Problem

---

## PROBLEM

### **Aktueller Status:**
- **AMP100:** ✅ Erkannt, Driver gebunden
- **Touchscreen:** ❌ Nicht erkannt, I2C Read/Write schlägt fehl

### **Mögliche Ursachen:**
1. **Kabel-Problem:** SDA/SCL Kabel vom DSP Add-on zum AMP100
2. **I2C Bus-Konflikt:** Beide Devices auf gleichem Bus
3. **Power-Supply:** 27W Pi 5 Netzteil möglicherweise unzureichend

---

## LÖSUNG

### **1. Kabel prüfen:**
- **SDA/SCL Kabel vom DSP Add-on zum AMP100:**
  - Verbindung prüfen
  - Kabel ersetzen falls nötig
  - **Auf einer Seite ersetzen** (DSP Add-on oder AMP100)

### **2. Hardware-Verbindung dokumentieren:**
- Welche Kabel wo verbunden
- Pin-Mapping
- Kabel-Typ und Länge

### **3. I2C-Kommunikation testen:**
- Nach Kabel-Ersatz
- I2C Read/Write Test
- Touchscreen Device erstellen

---

## NÄCHSTE SCHRITTE

1. ✅ Kabel-Verbindungen dokumentiert
2. ⏳ Kabel prüfen (Hardware)
3. ⏳ Kabel ersetzen falls nötig
4. ⏳ I2C-Kommunikation testen

---

**Im Projektplan integriert...**

