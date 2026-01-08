# Room Correction Wizard Fixes - v1.0

**Date:** January 7, 2026  
**Status:** ✅ Fixed and Deployed

## Issues Fixed

### 1. PID File Path Inconsistency
**Problem:** Pink noise PID file was using inconsistent paths:
- Some code used `/var/run/pink_noise.pid` (requires root permissions)
- Other code used `/tmp/pink_noise.pid` (user-writable)

**Fix:** Standardized to `/tmp/pink_noise.pid` for all pink noise operations:
- `start_pink_noise` - Uses `/tmp/pink_noise.pid`
- `stop_pink_noise` - Uses `/tmp/pink_noise.pid`
- `get_pink_noise_status` - Uses `/tmp/pink_noise.pid`

**Why:** `/tmp/` is writable by `www-data` user without sudo, making it more reliable.

### 2. Pink Noise Device Path
**Problem:** Using `plughw:$cardnum,0` which may not resolve correctly.

**Fix:** Changed to explicit device path: `plughw:CARD=sndrpihifiberry,DEV=0`

**Why:** Direct DAC output bypasses CamillaDSP during measurement, ensuring clean pink noise for accurate measurements.

### 3. Log File Management
**Added:** Log file at `/tmp/pink_noise.log` for debugging:
- Captures `speaker-test` output
- Helps diagnose pink noise issues
- Automatically cleaned up on stop

### 4. Improved Error Handling
**Added:**
- Stale PID file cleanup
- Better process detection
- More robust stop logic with sleep delay
- Automatic cleanup of dead processes

## Code Changes

### Before:
```php
$pid_file = '/var/run/pink_noise.pid';
$cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D plughw:$cardnum,0 > /dev/null 2>&1 & echo $!";
```

### After:
```php
$pid_file = '/tmp/pink_noise.pid';
$log_file = '/tmp/pink_noise.log';
$cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D plughw:CARD=sndrpihifiberry,DEV=0 > \"$log_file\" 2>&1 & echo \$!";
```

## Deployment

**File:** `moode-source/www/command/room-correction-wizard.php`  
**Deployed to:** `/var/www/command/room-correction-wizard.php`  
**Permissions:** `www-data:www-data`, `644`

## Verification

To verify the fix is working:

1. **Check PID file path:**
   ```bash
   grep "/tmp/pink_noise.pid" /var/www/command/room-correction-wizard.php
   ```

2. **Check device path:**
   ```bash
   grep "plughw:CARD=sndrpihifiberry" /var/www/command/room-correction-wizard.php
   ```

3. **Test pink noise:**
   - Start wizard on iPhone
   - Press "Start Measurement"
   - Should hear continuous pink noise
   - Check `/tmp/pink_noise.pid` exists
   - Check `/tmp/pink_noise.log` for output

## Expected Behavior

After fix:
- ✅ Pink noise starts reliably
- ✅ PID file created in `/tmp/` (writable by www-data)
- ✅ Direct DAC output (bypasses CamillaDSP)
- ✅ Log file captures output for debugging
- ✅ Stop command reliably kills process
- ✅ Stale PID files cleaned up automatically

---

**Fixed By:** Ghetto AI  
**Deployed:** January 7, 2026  
**System:** Ghetto Blaster v1.0

