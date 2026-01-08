# CRITICAL FINDINGS

**Date:** 2025-12-04  
**Status:** Research findings

---

## KEY DISCOVERY: HiFiBerryOS Configuration

### **HiFiBerryOS AMP100 Uses:**
1. **`dtoverlay=i2c-gpio`** (custom I2C bus)
2. **`dtparam=i2c_gpio_sda=0`**
3. **`dtparam=i2c_gpio_scl=1`**
4. **`dtoverlay=hifiberry-dacplus`** (NOT `hifiberry-amp100`!)

### **Current Pi 5 Configuration:**
- Uses `hifiberry-amp100` overlay
- Uses standard I2C (not i2c-gpio)
- I2C baudrate: 50kHz (changed to 100kHz)

---

## WEB RESEARCH FINDINGS

1. ✅ **AMP100 is compatible with Pi 5**
2. ✅ **Onboard sound must be disabled** (VC4) - Already done
3. ⚠️ **Need updated drivers** - Checking
4. ⚠️ **Power supply critical** - External 12-30V required

---

## NEXT TESTS

1. ⏳ Add `i2c-gpio` overlay (like HiFiBerryOS)
2. ⏳ Test with `hifiberry-dacplus` overlay instead of `amp100`
3. ⏳ Hardware reset sequence (GPIO17/GPIO4)

---

**Status:** Critical configuration differences identified

