# Pi 5 AMP100 Research

**Date:** 2025-12-04  
**Status:** Research in progress

---

## KEY FINDINGS

### **1. Hardware Detection:**
- ✅ Both systems detect: `snd-rpi-hifiberry-dacplus`
- ✅ Both show: GPIO4 for HW-MUTE, GPIO17 for HW-RESET
- ⚠️ HiFiBerryOS: Card 2, Pi 5: Card 0

### **2. MPD Configuration:**
- HiFiBerryOS uses: `device "default"`
- Pi 5 uses: `device "hw:0,0"`
- **Testing:** Switching Pi 5 to "default"

### **3. I2C Configuration:**
- Pi 5: `i2c_arm_baudrate=50000` (50kHz)
- **Testing:** Changing to 100000 (100kHz)

### **4. ALSA Configuration:**
- HiFiBerryOS: No `/etc/asound.conf` (uses system defaults)
- Pi 5: Simple `/etc/asound.conf` with `card 0`
- **Testing:** Using "default" device

---

## TESTS IN PROGRESS

1. ⏳ MPD with "default" device
2. ⏳ I2C baudrate 100kHz
3. ⏳ ALSA default device

---

**Status:** Testing different configurations

