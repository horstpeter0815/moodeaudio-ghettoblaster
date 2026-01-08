# PEPPYMETER ISSUES

**Date:** 2025-12-04  
**Status:** TESTING - Two issues reported

---

## ISSUES REPORTED

### **1. Indicators Not at Zero**
- **Symptom:** Indicators frozen at ~1/3 (not at zero)
- **Possible Causes:**
  - MPD not playing (no audio data)
  - FIFO pipe not receiving data
  - PeppyMeter showing last known values

### **2. Touch Doesn't Close PeppyMeter**
- **Symptom:** Touching screen doesn't close PeppyMeter
- **Possible Causes:**
  - Touch events not reaching screensaver script
  - hide_peppymeter function not being called
  - Service not running or not detecting touch

---

## DIAGNOSIS IN PROGRESS

- Checking MPD playback status
- Checking FIFO data flow
- Testing touch detection
- Verifying screensaver service functionality

---

**Status:** Testing - investigating both issues

