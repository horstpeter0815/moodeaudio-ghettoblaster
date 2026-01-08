# MULTIMETER TEST ANLEITUNG

**Datum:** 02.12.2025  
**Zweck:** Systematische Hardware-Diagnose mit Multimeter

---

## TEST 1: I2C BUS 1 SPANNUNG (IDLE)

### **Mess-Punkte:**
- **GPIO 2 (Pin 3):** SDA
- **GPIO 3 (Pin 5):** SCL
- **GND (Pin 6):** Ground

### **Erwartete Werte:**
- **SDA:** ~3.3V (high)
- **SCL:** ~3.3V (high)
- **GND:** 0V

### **Durchführung:**
1. Multimeter auf DC Voltage (V)
2. Schwarzes Kabel an GND (Pin 6)
3. Rotes Kabel an GPIO 2 (Pin 3) → SDA messen
4. Rotes Kabel an GPIO 3 (Pin 5) → SCL messen

---

## TEST 2: I2C BUS 10 SPANNUNG (IDLE)

### **Mess-Punkte:**
- **Touchscreen SDA Pin:** Am Touchscreen-Connector
- **Touchscreen SCL Pin:** Am Touchscreen-Connector
- **Touchscreen GND Pin:** Am Touchscreen-Connector

### **Erwartete Werte:**
- **SDA:** ~3.3V (high)
- **SCL:** ~3.3V (high)
- **GND:** 0V

### **Durchführung:**
1. Multimeter auf DC Voltage (V)
2. Schwarzes Kabel an Touchscreen GND
3. Rotes Kabel an Touchscreen SDA → Spannung messen
4. Rotes Kabel an Touchscreen SCL → Spannung messen

---

## TEST 3: TOUCHSCREEN POWER SUPPLY

### **Mess-Punkte:**
- **Touchscreen VCC Pin:** Power-Supply
- **Touchscreen GND Pin:** Ground

### **Erwartete Werte:**
- **VCC:** 3.3V ± 0.1V oder 5V ± 0.1V (je nach Touchscreen)

### **Durchführung:**
1. Multimeter auf DC Voltage (V)
2. Schwarzes Kabel an GND
3. Rotes Kabel an VCC → Spannung messen
4. **Während I2C-Zugriff messen:** Spannung sollte stabil bleiben

---

## TEST 4: KABEL-KONTINUITÄT

### **Mess-Punkte:**
- **Raspberry Pi GPIO 2 → Touchscreen SDA**
- **Raspberry Pi GPIO 3 → Touchscreen SCL**
- **Raspberry Pi GND → Touchscreen GND**

### **Erwartete Werte:**
- **Kontinuität:** < 1Ω (gute Verbindung)
- **Keine Kontinuität:** Kabel defekt oder lose

### **Durchführung:**
1. Multimeter auf Continuity (Ω)
2. Ein Kabel an GPIO 2, anderes an Touchscreen SDA
3. Sollte "beep" oder < 1Ω zeigen
4. Wiederholen für SCL und GND

---

## TEST 5: PULL-UP RESISTORS

### **Mess-Punkte:**
- **SDA zu 3.3V:** Widerstand prüfen
- **SCL zu 3.3V:** Widerstand prüfen

### **Erwartete Werte:**
- **Pull-up Resistor:** 2.2kΩ oder 4.7kΩ (typisch)
- **Ohne Pull-up:** ∞ (offen) → I2C funktioniert nicht

### **Durchführung:**
1. Multimeter auf Resistance (Ω)
2. Ein Kabel an SDA, anderes an 3.3V
3. Widerstand messen
4. Wiederholen für SCL

---

## TEST 6: KURZSCHLUSS-TEST

### **Mess-Punkte:**
- **SDA gegen GND:** Sollte hochohmig sein
- **SCL gegen GND:** Sollte hochohmig sein
- **SDA gegen VCC:** Sollte hochohmig sein (außer über Pull-up)

### **Erwartete Werte:**
- **Kein Kurzschluss:** > 1kΩ
- **Kurzschluss:** < 10Ω → Problem!

### **Durchführung:**
1. Multimeter auf Resistance (Ω)
2. Ein Kabel an SDA, anderes an GND
3. Sollte hochohmig sein (> 1kΩ)
4. Wiederholen für alle Kombinationen

---

## TEST 7: I2C AKTIVITÄT WÄHREND MESSUNG

### **Durchführung:**
1. Multimeter auf DC Voltage (V)
2. Kabel an SDA oder SCL
3. **Während I2C-Zugriff:** Spannung sollte pulsieren (0V ↔ 3.3V)
4. **Wenn keine Pulsation:** I2C Kommunikation schlägt fehl

### **I2C-Zugriff generieren:**
```bash
sudo i2cdetect -y 10
sudo i2cget -y 10 0x45 0x00 b
```

---

## ERGEBNISSE DOKUMENTIEREN

Für jeden Test:
- ✅ **OK:** Wert im erwarteten Bereich
- ❌ **FEHLER:** Wert außerhalb erwarteter Bereich
- ⚠️ **UNKLAR:** Wert ungewöhnlich, aber nicht eindeutig fehlerhaft

---

**Systematische Hardware-Diagnose mit Multimeter...**

