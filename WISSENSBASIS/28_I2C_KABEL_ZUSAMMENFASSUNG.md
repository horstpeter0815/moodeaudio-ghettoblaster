# I2C KABEL-PROBLEM ZUSAMMENFASSUNG

**Datum:** 02.12.2025  
**Status:** Hardware-Analyse abgeschlossen, Kabel-Prüfung ausstehend

---

## ✅ ERKANNT

### **AMP100 PCM5122:**
- **I2C Bus:** Bus 1
- **Adresse:** 0x4d
- **Driver:** pcm512x (gebunden)
- **Device:** `/sys/bus/i2c/devices/i2c-1/1-004d`
- **Status:** ✅ Funktioniert

---

## ❌ PROBLEM

### **Touchscreen FT6236:**
- **I2C Bus:** Bus 1
- **Adresse:** 0x38
- **Device:** Existiert nicht
- **Driver:** Nicht gebunden
- **I2C Read/Write:** Schlägt fehl
- **Status:** ❌ Funktioniert nicht

---

## 🔍 MÖGLICHE URSACHEN

1. **Kabel-Problem:**
   - SDA/SCL Kabel vom DSP Add-on zum AMP100
   - Falsch verbunden, defekt oder lose Verbindung

2. **I2C Bus-Konflikt:**
   - Beide Devices auf gleichem Bus (GPIO 2/3)
   - Timing-Problem beim Boot

3. **Power-Supply:**
   - 27W Pi 5 Netzteil für Pi 4 + AMP100
   - Möglicherweise unzureichend

---

## 📋 NÄCHSTE SCHRITTE

1. ✅ I2C-Architektur analysiert
2. ✅ Kabel-Verbindungen dokumentiert
3. ⏳ **Kabel prüfen (Hardware)**
4. ⏳ **Kabel ersetzen falls nötig** (auf einer Seite)
5. ⏳ I2C-Kommunikation testen

---

## 📚 VERWANDTE DOKUMENTE

- [I2C Architektur Analyse](22_I2C_ARCHITEKTUR_ANALYSE.md)
- [I2C Kabel-Verbindungen](23_I2C_KABEL_VERBINDUNGEN.md)
- [Hardware Kabel-Analyse](26_HARDWARE_KABEL_ANALYSE.md)
- [Kabel-Problem Lösung](27_KABEL_PROBLEM_LOESUNG.md)

---

**Im Projektplan integriert...**
