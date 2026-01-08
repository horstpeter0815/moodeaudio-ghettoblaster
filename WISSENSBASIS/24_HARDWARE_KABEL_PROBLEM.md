# HARDWARE KABEL-PROBLEM ANALYSE

**Datum:** 02.12.2025  
**Problem:** I2C-Kommunikation schlägt fehl - möglicherweise Kabel-Problem

---

## HARDWARE-SETUP

### **DSP Add-on zu AMP100:**
- **2 Kabel:** SDA und SCL
- **Verbindung:** DSP Add-on → AMP100 (PCM5122)

### **I2C Bus 1:**
- **GPIO 2 (Pin 3):** SDA
- **GPIO 3 (Pin 5):** SCL
- **Devices:**
  - AMP100 PCM5122: 0x4d
  - Touchscreen FT6236: 0x38

---

## MÖGLICHE KABEL-PROBLEME

### **1. Kabel-Verbindung:**
- SDA/SCL Kabel falsch verbunden?
- Kabel defekt?
- Lose Verbindung?

### **2. Kabel ersetzen:**
- Kabel auf einer Seite ersetzen (DSP Add-on oder AMP100)
- Prüfe Verbindungen

---

## LÖSUNGSANSÄTZE

1. **Kabel prüfen:**
   - SDA/SCL Verbindung prüfen
   - Kabel ersetzen falls nötig

2. **Hardware-Verbindung dokumentieren:**
   - Welche Kabel wo verbunden
   - Pin-Mapping

---

**Hardware-Analyse in Arbeit...**

