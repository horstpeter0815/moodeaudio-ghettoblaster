# MULTIMETER TEST PLAN - WAVESHARE TOUCHSCREEN

**Datum:** 02.12.2025  
**Hardware:** WaveShare 7.9-inch Panel, Goodix Touchscreen  
**Problem:** I2C Error -5 auf Bus 10

---

## MULTIMETER TESTS

### **1. I2C BUS 10 SPANNUNG:**
- **SDA (Data Line):** Sollte ~3.3V sein (idle high)
- **SCL (Clock Line):** Sollte ~3.3V sein (idle high)
- **GND:** Sollte 0V sein
- **VCC:** Sollte 3.3V oder 5V sein (je nach Touchscreen)

### **2. TOUCHSCREEN POWER SUPPLY:**
- **VCC Pin:** Spannung prüfen (sollte stabil sein)
- **GND Pin:** Kontinuität prüfen
- **Power unter Last:** Spannung während I2C-Zugriff prüfen

### **3. I2C KABEL-VERBINDUNG:**
- **Kontinuität SDA:** Kabel-Verbindung prüfen
- **Kontinuität SCL:** Kabel-Verbindung prüfen
- **Kurzschluss-Test:** SDA/SCL gegen GND/VCC prüfen

### **4. PULL-UP RESISTORS:**
- **SDA Pull-up:** Widerstand prüfen (sollte ~2.2kΩ oder 4.7kΩ)
- **SCL Pull-up:** Widerstand prüfen
- **Ohne Pull-ups:** I2C funktioniert nicht richtig

### **5. I2C BUS 1 VS BUS 10:**
- **Bus 1 SDA/SCL:** Spannung prüfen
- **Bus 10 SDA/SCL:** Spannung prüfen
- **Vergleich:** Unterschiede identifizieren

---

## MESS-PUNKTE

### **Raspberry Pi 4 GPIO:**
- **GPIO 2 (Pin 3):** SDA für Bus 1
- **GPIO 3 (Pin 5):** SCL für Bus 1
- **Bus 10:** Via I2C Mux (andere Pins)

### **Touchscreen:**
- **SDA Pin:** Am Touchscreen-Connector
- **SCL Pin:** Am Touchscreen-Connector
- **VCC Pin:** Power-Supply
- **GND Pin:** Ground

---

## ERWARTETE WERTE

### **I2C Bus (idle):**
- **SDA:** 3.3V (high)
- **SCL:** 3.3V (high)
- **GND:** 0V

### **Pull-up Resistors:**
- **Typisch:** 2.2kΩ oder 4.7kΩ
- **Ohne Pull-ups:** I2C funktioniert nicht

### **Power Supply:**
- **3.3V Touchscreen:** 3.3V ± 0.1V
- **5V Touchscreen:** 5V ± 0.1V

---

**Test-Plan erstellt, Messungen durchführen...**

