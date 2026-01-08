# KABEL-REPARATUR TEST

**Datum:** 02.12.2025  
**Aktion:** SDA/SCL Kabel am DSP überprüft und neu verbunden

---

## DURCHGEFÜHRTE REPARATUR

### **Problem:**
- SDA/SCL Kabel am DSP möglicherweise versehentlich herausgezogen
- I2C-Kommunikation schlug fehl

### **Reparatur:**
- Kabel am DSP überprüft
- SDA/SCL neu verbunden
- System neu gestartet

---

## TEST-ERGEBNISSE

### **Nach Reboot:**
- ⏳ I2C Bus 1 Status prüfen
- ⏳ AMP100 PCM5122 Status prüfen
- ⏳ Touchscreen FT6236 Status prüfen
- ⏳ I2C Read/Write Test
- ⏳ Touchscreen Device erstellen
- ⏳ Touchscreen in xinput prüfen

---

## ERWARTETE ERGEBNISSE

### **Erfolg:**
- ✅ Touchscreen Device existiert: `/sys/bus/i2c/devices/i2c-1/1-0038`
- ✅ Driver gebunden: `edt-ft5x06`
- ✅ Input Device erstellt: `/dev/input/eventX`
- ✅ Touchscreen in xinput erkannt

### **Falls weiterhin Problem:**
- ⚠️ Weitere Hardware-Prüfung nötig
- ⚠️ Power-Supply prüfen
- ⚠️ Alternative I2C Bus testen

---

**Test in Arbeit...**

