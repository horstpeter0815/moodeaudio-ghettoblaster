# I2C KABEL-VERBINDUNGEN ANALYSE

**Datum:** 02.12.2025  
**Problem:** I2C-Kommunikation schlägt fehl (Read/Write Error)

---

## I2C HARDWARE-VERBINDUNGEN

### **Raspberry Pi 4 I2C Bus 1:**
- **GPIO 2 (Pin 3):** SDA (Data)
- **GPIO 3 (Pin 5):** SCL (Clock)

### **DSP Add-on zu AMP100 Kabel:**
- **SDA:** DSP Add-on → AMP100 (PCM5122 SDA Pin)
- **SCL:** DSP Add-on → AMP100 (PCM5122 SCL Pin)

### **Touchscreen I2C-Verbindung:**
- **SDA:** GPIO 2 (Pin 3) - **GLEICHER PIN WIE AMP100!**
- **SCL:** GPIO 3 (Pin 5) - **GLEICHER PIN WIE AMP100!**
- **Adresse:** 0x38

---

## MÖGLICHE PROBLEME

### **1. Kabel-Verbindung:**
- SDA/SCL Kabel vom DSP Add-on zum AMP100
- Möglicherweise falsch verbunden
- Möglicherweise defekt
- Möglicherweise lose Verbindung

### **2. I2C Bus-Konflikt:**
- AMP100 (0x4d) und Touchscreen (0x38) auf gleichem Bus
- Beide verwenden GPIO 2/3
- I2C ist Multi-Master - sollte funktionieren
- ABER: Timing-Problem möglich

### **3. Power-Supply:**
- Pi 4 mit 27W Pi 5 Netzteil
- AMP100 benötigt zusätzlichen Strom
- Touchscreen möglicherweise unterversorgt

---

## LÖSUNGSANSÄTZE

1. **Kabel prüfen:**
   - SDA/SCL Kabel vom DSP Add-on zum AMP100
   - Verbindung prüfen
   - Kabel ersetzen falls nötig

2. **I2C Bus trennen:**
   - Touchscreen auf anderen Bus (falls möglich)
   - Oder AMP100 auf anderen Bus

3. **Power-Supply prüfen:**
   - Ausreichendes Netzteil für Pi 4 + AMP100

---

**Systematische Hardware-Analyse in Arbeit...**

