# HARDWARE TEST PLAN - WAVESHARE TOUCHSCREEN

**Datum:** 02.12.2025  
**Zweck:** Systematische Hardware-Diagnose für I2C Error -5

---

## STANDARD HARDWARE-TESTS

### **1. I2C BUS HARDWARE-TEST:**
- I2C Bus 10 Funktionalität prüfen
- Alternative I2C Devices auf Bus 10 testen
- I2C Bus 10 vs andere Busse vergleichen

### **2. TOUCHSCREEN HARDWARE-TEST:**
- Touchscreen auf anderen I2C Bus testen
- Touchscreen mit Multimeter prüfen (wenn möglich)
- Power-Supply am Touchscreen prüfen

### **3. KABEL-VERBINDUNG TEST:**
- I2C Kabel-Verbindung physisch prüfen
- SDA/SCL Kabel tauschen
- Kabel-Widerstand prüfen (wenn Multimeter verfügbar)

### **4. POWER-SUPPLY TEST:**
- Spannung am Touchscreen prüfen
- Strom-Verbrauch prüfen
- Power-Supply unter Last testen

### **5. ALTERNATIVE HARDWARE-TEST:**
- Touchscreen auf anderen Raspberry Pi testen
- Anderen Touchscreen auf diesem Pi testen
- I2C Bus 10 mit anderem Device testen

---

## DURCHFÜHRBARE SOFTWARE-TESTS

### **1. I2C Bus Funktionalität:**
- I2C Bus 10 mit anderem Device testen
- I2C Bus 10 Speed testen
- I2C Bus 10 Timing testen

### **2. I2C Bus Vergleich:**
- I2C Bus 1 vs Bus 10 vergleichen
- Touchscreen auf Bus 1 testen (falls möglich)

### **3. I2C Kommunikation:**
- I2C Read/Write mit verschiedenen Methoden
- I2C SMBus vs I2C Block Data

---

**Test-Plan erstellt, Tests werden durchgeführt...**

