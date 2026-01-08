# WAVESHARE TOUCHSCREEN - BUS 10

**Datum:** 02.12.2025  
**Erkenntnis:** Neuer Touchscreen ist WaveShare auf I2C Bus 10!

---

## ERKENNTNIS

### **Neuer Touchscreen:**
- **Typ:** WaveShare Touchscreen
- **Controller:** Goodix
- **I2C Bus:** Bus 10 (nicht Bus 1!)
- **I2C Adresse:** 0x45
- **Device:** `/sys/bus/i2c/devices/i2c-10/10-0045/`

### **dmesg zeigt:**
```
ws_touchscreen 10-0045: I2C write failed: -5
```

---

## ANALYSE

### **Unterschied zum alten Touchscreen:**
- **Alter:** FT6236 auf Bus 1, Adresse 0x38
- **Neu:** WaveShare/Goodix auf Bus 10, Adresse 0x45

### **Module geladen:**
- `panel_waveshare_dsi` - Display Panel
- `goodix_ts` - Goodix Touchscreen Driver

---

## TEST-ERGEBNISSE

### **I2C Bus 10:**
- ⏳ Scan durchgeführt
- ⏳ WaveShare Device geprüft
- ⏳ Driver-Bindung geprüft

### **Touchscreen:**
- ⏳ Input Device geprüft
- ⏳ xinput geprüft
- ⏳ I2C Read/Write getestet

---

## ERWARTETE ERGEBNISSE

### **Erfolg:**
- ✅ WaveShare Device existiert
- ✅ Goodix Driver gebunden
- ✅ Input Device erstellt
- ✅ Touchscreen in xinput erkannt
- ✅ I2C Read/Write funktioniert

### **Falls weiterhin Problem:**
- ⚠️ I2C Write Error -5 (wie im dmesg)
- ⚠️ Driver-Konfiguration nötig
- ⚠️ Calibration nötig

---

**Test in Arbeit...**

