# MULTIMETER TEST ERGEBNISSE

**Datum:** 02.12.2025  
**Tests:** Hardware-Diagnose mit Multimeter

---

## TEST 1: I2C BUS 1 SPANNUNG (IDLE)

### **Mess-Punkte:**
- GPIO 2 (Pin 3): SDA
- GPIO 3 (Pin 5): SCL

### **Erwartete Werte:**
- SDA: ~3.3V
- SCL: ~3.3V

### **Ergebnis:**
⏳ Wird gemessen...

---

## TEST 2: I2C BUS 10 SPANNUNG (IDLE)

### **Mess-Punkte:**
- Touchscreen SDA Pin
- Touchscreen SCL Pin

### **Erwartete Werte:**
- SDA: ~3.3V
- SCL: ~3.3V

### **Ergebnis:**
⏳ Wird gemessen...

---

## TEST 3: TOUCHSCREEN POWER SUPPLY

### **Mess-Punkte:**
- Touchscreen VCC Pin
- Touchscreen GND Pin

### **Erwartete Werte:**
- VCC: 3.3V ± 0.1V oder 5V ± 0.1V

### **Ergebnis:**
⏳ Wird gemessen...

---

## TEST 4: KABEL-KONTINUITÄT

### **Mess-Punkte:**
- GPIO 2 → Touchscreen SDA
- GPIO 3 → Touchscreen SCL
- GND → Touchscreen GND

### **Erwartete Werte:**
- Kontinuität: < 1Ω

### **Ergebnis:**
⏳ Wird gemessen...

---

## TEST 5: PULL-UP RESISTORS

### **Mess-Punkte:**
- SDA zu 3.3V
- SCL zu 3.3V

### **Erwartete Werte:**
- Pull-up: 2.2kΩ oder 4.7kΩ

### **Ergebnis:**
⏳ Wird gemessen...

---

## TEST 6: KURZSCHLUSS-TEST

### **Mess-Punkte:**
- SDA gegen GND
- SCL gegen GND
- SDA gegen VCC

### **Erwartete Werte:**
- Kein Kurzschluss: > 1kΩ

### **Ergebnis:**
⏳ Wird gemessen...

---

## TEST 7: I2C AKTIVITÄT

### **Mess-Punkte:**
- SDA während I2C-Zugriff
- SCL während I2C-Zugriff

### **Erwartete Werte:**
- Pulsation: 0V ↔ 3.3V

### **Ergebnis:**
⏳ Wird gemessen...

---

---

## ZUSAMMENFASSUNG

### **WICHTIGE ERKENNTNISSE:**

1. **I2C Bus 1:** ✅ Funktioniert (AMP100 erkannt auf 0x4d)
2. **I2C Bus 10:** ⚠️ Touchscreen zeigt "UU" (unbekannt, aber erkannt)
3. **Goodix auf Bus 1:** ❌ Read failed (Device erstellt, aber keine Kommunikation)
4. **Goodix auf Bus 10:** ❌ I2C Error -5 (bekanntes Problem)

### **MULTIMETER-TESTS DURCHFÜHREN:**

**TEST 1: I2C Bus 1 Spannung (idle)**
- GPIO 2 (Pin 3): SDA → sollte ~3.3V sein
- GPIO 3 (Pin 5): SCL → sollte ~3.3V sein

**TEST 2: I2C Bus 10 Spannung (idle)**
- Touchscreen SDA Pin → sollte ~3.3V sein
- Touchscreen SCL Pin → sollte ~3.3V sein

**TEST 3: Touchscreen Power Supply**
- Touchscreen VCC → sollte 3.3V oder 5V sein

**TEST 4: Kabel-Kontinuität**
- GPIO 2 → Touchscreen SDA → sollte < 1Ω sein
- GPIO 3 → Touchscreen SCL → sollte < 1Ω sein

**TEST 5: Pull-up Resistors**
- SDA zu 3.3V → sollte 2.2kΩ oder 4.7kΩ sein
- SCL zu 3.3V → sollte 2.2kΩ oder 4.7kΩ sein

**TEST 6: Kurzschluss-Test**
- SDA gegen GND → sollte > 1kΩ sein
- SCL gegen GND → sollte > 1kΩ sein

**TEST 7: I2C Aktivität**
- Während `i2cdetect -y 10` → SDA/SCL sollten pulsieren (0V ↔ 3.3V)

---

**Messungen durchführen und Ergebnisse dokumentieren...**

