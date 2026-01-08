# Wizard Pink Noise - Final Fix

**Date:** January 7, 2026  
**Issue:** Pink noise not playing despite process starting  
**Status:** ✅ Fixed - Using sox with plughw and MPD service stop

## Problem

- Pink noise process started (PID created)
- But no audio was heard
- Multiple attempts with speaker-test failed
- Device access issues

## Root Cause

1. **MPD service holding device** - Even when stopped, MPD service holds the audio device
2. **Volume control bypassed** - Using `hw:0,0` bypasses ALSA volume mixer
3. **speaker-test unreliable** - Process may crash or not route audio correctly

## Solution

### 1. Stop MPD Service Completely
```php
sysCmd("mpc stop 2>/dev/null");
sysCmd("systemctl stop mpd 2>/dev/null");
sleep(2); // Give MPD time to fully release the audio device
```

### 2. Use sox Instead of speaker-test
- More reliable ALSA integration
- Better error handling
- Continuous pink noise generation

### 3. Use plughw for Volume Control
```php
$cmd = "sox -n -t alsa plughw:0,0 synth pinknoise gain -10 > \"$log_file\" 2>&1 & echo \$!";
```

**Why plughw:**
- `hw:0,0` = Direct hardware, bypasses volume mixer (no sound if volume low)
- `plughw:0,0` = Hardware with volume control (respects ALSA mixer volume)

### 4. Restore MPD Service
```php
sysCmd("systemctl start mpd 2>/dev/null");
sleep(2); // Give MPD time to start
// Then restore playback if it was playing
```

## Code Changes

### Before:
```php
sysCmd("mpc stop 2>/dev/null");
sleep(1);
$cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D hw:0,0 > \"$log_file\" 2>&1 & echo \$!";
```

### After:
```php
sysCmd("mpc stop 2>/dev/null");
sysCmd("systemctl stop mpd 2>/dev/null");
sleep(2);
$cmd = "sox -n -t alsa plughw:0,0 synth pinknoise gain -10 > \"$log_file\" 2>&1 & echo \$!";
```

## Testing

To verify the fix:

1. **Stop MPD service:**
   ```bash
   systemctl stop mpd
   ```

2. **Set volume:**
   ```bash
   amixer -c 0 sset Digital unmute
   amixer -c 0 sset Digital 200  # 78% - should be audible
   ```

3. **Test sox:**
   ```bash
   sox -n -t alsa plughw:0,0 synth 5 pinknoise gain -10
   # Should hear 5 seconds of pink noise
   ```

4. **Test via wizard:**
   - Press "Start Measurement" on iPhone
   - Should hear continuous pink noise
   - MPD service will be stopped automatically

## Expected Behavior

1. User presses "Start Measurement"
2. MPD service stops completely
3. sox starts generating pink noise via `plughw:0,0`
4. User hears continuous pink noise (respects ALSA volume)
5. When stopped, MPD service restarts and playback resumes (if was playing)

## Troubleshooting

If still no sound:

1. **Check MPD service:**
   ```bash
   systemctl status mpd
   # Should be stopped during pink noise
   ```

2. **Check volume:**
   ```bash
   amixer -c 0 sget Digital
   # Should show [on] and volume > 0
   ```

3. **Check process:**
   ```bash
   ps aux | grep sox
   # Should show sox process running
   ```

4. **Check logs:**
   ```bash
   cat /tmp/pink_noise.log
   # Look for errors
   ```

5. **Test manually:**
   ```bash
   systemctl stop mpd
   sox -n -t alsa plughw:0,0 synth 5 pinknoise gain -10
   # Should hear pink noise immediately
   ```

---

**Fixed By:** Ghetto AI  
**Deployed:** January 7, 2026  
**System:** Ghetto Blaster v1.0
