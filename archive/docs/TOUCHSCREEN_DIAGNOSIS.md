# Touchscreen Diagnosis - Waveshare 7.9" HDMI Display

**Datum:** $(date)  
**Hardware:** Raspberry Pi 5, Waveshare 7.9" HDMI LCD  
**Touch Controller:** Goodix GT911 (erwartet auf I2C 0x14)

---

## 🔍 Diagnose-Ergebnisse

### I2C Buses
- **Bus 0:** Standard I2C
- **Bus 1:** Standard I2C  
- **Bus 10:** DSI I2C (falls verfügbar)

### Erwartete I2C Adressen
- **0x14:** Goodix GT911 Touch Controller
- **0x45:** Panel Controller (nur bei DSI)

### Touchscreen Module
- `ws_touchscreen` - Waveshare Touchscreen Driver
- `goodix` - Goodix Touch Controller Driver

### Input Devices
- `/dev/input/event*` - Touchscreen Event Devices
- `xinput` - X11 Input Configuration

---

## 📋 Prüfschritte

1. ✅ I2C Buses scannen
2. ✅ Input Devices prüfen
3. ✅ Touchscreen Drivers prüfen
4. ✅ Device Tree Overlays prüfen
5. ✅ dmesg Messages prüfen
6. ✅ Touchscreen Events testen

---

**Status:** ⏳ Diagnose läuft...

