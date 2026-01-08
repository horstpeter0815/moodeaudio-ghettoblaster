# NEW AMP100 HARDWARE TEST

**Date:** 2025-12-04  
**Status:** TESTING - New AMP100 board connected

---

## HARDWARE CHANGE

- **Previous:** First new AMP100 board (not working)
- **Current:** Second new AMP100 board (testing)
- **Both:** Were new boards

---

## TESTING

Checking if new AMP100 board is:
1. Detected by system
2. Recognized as audio hardware
3. Working with current configuration

---

## DIAGNOSIS

- Checking `aplay -l` for soundcards
- Checking `/proc/asound/cards` for ALSA cards
- Checking dmesg for I2C/AMP100 detection
- Checking current configuration

---

**Status:** Testing new hardware - nothing verified yet

