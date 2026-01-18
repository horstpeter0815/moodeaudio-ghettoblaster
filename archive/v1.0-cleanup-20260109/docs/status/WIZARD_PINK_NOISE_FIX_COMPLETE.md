# Wizard Pink Noise - Complete Fix

**Date:** January 7, 2026  
**Status:** ✅ Fixed and Deployed

## Final Solution

### Changes Made:

1. **Stop MPD Service Completely**
   - `mpc stop` + `systemctl stop mpd`
   - Ensures audio device is fully released
   - Wait 2 seconds for device release

2. **Use sox Instead of speaker-test**
   - More reliable ALSA integration
   - Better error handling
   - Continuous pink noise generation

3. **Use plughw for Volume Control**
   - `plughw:0,0` instead of `hw:0,0`
   - Goes through ALSA volume mixer
   - Respects `amixer -c 0` volume settings

4. **Restore MPD Service**
   - Always restart MPD service after stopping
   - Restore playback if it was playing before

## Code

```php
// Stop MPD service completely
sysCmd("mpc stop 2>/dev/null");
sysCmd("systemctl stop mpd 2>/dev/null");
sleep(2);

// Ensure volume is unmuted
sysCmd("amixer -c 0 sset Digital unmute 2>/dev/null");

// Start pink noise with sox
$cmd = "sox -n -t alsa plughw:0,0 synth pinknoise gain -10 > \"$log_file\" 2>&1 & echo \$!";
```

## Testing

The fix has been deployed. To test:

1. **Press "Start Measurement" on iPhone**
2. **You should hear continuous pink noise**
3. **MPD service will stop automatically**
4. **When you stop, MPD service will restart**

## Verification

- ✅ sox test with `plughw:0,0` works (confirmed)
- ✅ MPD service stop/start works (confirmed)
- ✅ Process starts and runs (confirmed)
- ✅ Volume control works (plughw respects mixer)

---

**Fixed By:** Ghetto AI  
**Deployed:** January 7, 2026  
**System:** Ghetto Blaster v1.0

