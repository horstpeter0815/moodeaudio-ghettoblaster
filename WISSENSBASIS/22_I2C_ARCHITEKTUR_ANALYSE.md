# I2C ARCHITEKTUR ANALYSE

**Datum:** 02.12.2025  
**Ziel:** I2C-Kommunikationsproblem auf PI 4 verstehen und lösen

---

## I2C AUF RASPBERRY PI 4

### **I2C Busse:**
- **I2C Bus 0:** GPIO 0 (SDA), GPIO 1 (SCL) - Standard I2C
- **I2C Bus 1:** GPIO 2 (SDA), GPIO 3 (SCL) - Standard I2C

### **Hardware-Verbindungen:**
- **Touchscreen (FT6236):** I2C Bus 1, Adresse 0x38
- **AMP100 PCM5122:** I2C Bus 1, Adresse 0x4d
- **Beide auf gleichem Bus!**

---

## MÖGLICHE PROBLEME

### **1. I2C Bus-Konflikt:**
- AMP100 lädt beim Boot (Overlay)
- Touchscreen versucht später zu laden
- Möglicherweise Bus-Konflikt oder Timing-Problem

### **2. Power-Supply:**
- Pi 4 mit 27W Pi 5 Netzteil
- AMP100 benötigt zusätzlichen Strom
- Touchscreen möglicherweise unterversorgt

### **3. Hardware-Verbindung:**
- I2C-Kabel, Stecker
- GPIO-Pins korrekt verbunden?

---

## LÖSUNGSANSÄTZE

1. **AMP100 Overlay deaktivieren** (Test)
2. **I2C Bus 0 verwenden** (falls verfügbar)
3. **Power-Supply prüfen**
4. **Hardware-Verbindungen prüfen**

---

**Systematische Analyse in Arbeit...**

