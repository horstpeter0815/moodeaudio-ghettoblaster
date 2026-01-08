# AMP100 FIFO FIX

**Date:** 2025-12-04  
**Status:** TESTING - Added FIFO output to MPD

---

## ISSUE

- **Problem:** PeppyMeter indicators not updating
- **Root Cause:** MPD only had ALSA output, no FIFO output
- **Solution:** Added FIFO output alongside ALSA output

---

## CONFIGURATION

MPD now has TWO outputs:
1. **FIFO:** `/tmp/mpd.fifo` (for PeppyMeter)
2. **ALSA:** `hw:0,0` (for actual audio playback)

---

## EXPECTED BEHAVIOR

- Audio plays through AMP100 (ALSA output)
- PeppyMeter receives data from FIFO
- Indicators should update with audio

---

## TESTING

- Check if FIFO has data now
- Verify PeppyMeter indicators update
- Confirm audio still plays

---

**Status:** Configuration updated - testing required

