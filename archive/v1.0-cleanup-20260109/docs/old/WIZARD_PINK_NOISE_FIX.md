# Wizard Pink Noise Fix - MPD Conflict Resolution

**Date:** January 7, 2026  
**Issue:** Pink noise not playing because MPD was using the audio device  
**Status:** ✅ Fixed

## Problem

When user pressed "Start Measurement":
- Pink noise process started (PID created)
- But no audio was heard
- MPD was still active and using the audio device
- `speaker-test` couldn't access the device (Device or resource busy)

## Root Cause

MPD (Music Player Daemon) was actively using the ALSA audio device. When `speaker-test` tried to access `plughw:CARD=sndrpihifiberry,DEV=0`, it went through the ALSA plugin chain which was already locked by MPD.

## Solution

### 1. Stop MPD Before Starting Pink Noise
- Check if MPD is playing/paused
- Save MPD state (current track, position) to `/tmp/mpd_state_before_pink_noise.json`
- Stop MPD with `mpc stop`
- Wait 1 second for device to be released

### 2. Use Direct Hardware Access
- Changed from `plughw:CARD=sndrpihifiberry,DEV=0` (goes through ALSA plugins)
- To `hw:CARD=sndrpihifiberry,DEV=0` (direct hardware access)
- This bypasses ALSA plugins and MPD routing

### 3. Restore MPD After Stopping Pink Noise
- When pink noise stops, check if MPD was playing before
- Restore MPD playback with `mpc play`
- Clean up state file

## Code Changes

### Before:
```php
$cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D plughw:CARD=sndrpihifiberry,DEV=0 > \"$log_file\" 2>&1 & echo \$!";
```

### After:
```php
// Stop MPD first
sysCmd("mpc stop 2>/dev/null");
sleep(1);

// Use direct hardware access
$cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D hw:CARD=sndrpihifiberry,DEV=0 > \"$log_file\" 2>&1 & echo \$!";
```

## Expected Behavior

1. **User presses "Start Measurement":**
   - MPD stops (if playing)
   - MPD state saved
   - Pink noise starts via direct hardware access
   - User hears continuous pink noise

2. **User presses "Stop Measurement":**
   - Pink noise stops
   - MPD restores (if it was playing before)
   - Audio device released

## Testing

To test the fix:

1. **Start MPD playing a track:**
   ```bash
   mpc play
   ```

2. **Start wizard measurement:**
   - Should hear pink noise
   - MPD should stop automatically

3. **Stop wizard measurement:**
   - Pink noise stops
   - MPD should resume playing (if it was playing before)

## Notes

- **MPD State:** Saved to `/tmp/mpd_state_before_pink_noise.json`
- **Device Access:** Uses `hw:` for direct hardware (bypasses ALSA plugins)
- **Volume:** Controlled by ALSA volume (`amixer -c 0`), not MPD volume
- **No MPD Activity:** MPD won't show activity during pink noise (expected - it's stopped)

---

**Fixed By:** Ghetto AI  
**Deployed:** January 7, 2026  
**System:** Ghetto Blaster v1.0

