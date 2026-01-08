# PEPPYMETER FIFO FIX ATTEMPT

**Date:** 2025-12-04  
**Status:** TESTING - Attempting to fix frozen indicators

---

## ISSUE IDENTIFIED

- **Problem:** PeppyMeter indicators frozen at ~1/3
- **Root Cause:** MPD not configured to output to FIFO pipe `/tmp/mpd.fifo`
- **Current:** MPD only has ALSA output, no FIFO output
- **PeppyMeter expects:** Data from `/tmp/mpd.fifo`

---

## SOLUTION ATTEMPT

1. Create FIFO pipe `/tmp/mpd.fifo` if it doesn't exist
2. Add FIFO output to MPD configuration
3. Restart MPD service
4. Test if PeppyMeter receives data

---

## CONFIGURATION NEEDED

Add to `/etc/mpd.conf`:
```
audio_output {
    type "fifo"
    name "PeppyMeter FIFO"
    path "/tmp/mpd.fifo"
    format "44100:16:2"
}
```

---

**Status:** Testing - not verified yet

