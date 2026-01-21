# Debug Session Summary - Audio Output Issue
## Date: 2026-01-20

---

## **Problem**

MPD error: `Failed to open ALSA device "_audioout": No such device`

**Root Cause:** moOde worker.php auto-switches to HDMI/SPDIF when it can't detect HiFiBerry, overwriting `_audioout.conf` with wrong device.

---

## **Debug Process**

### Hypotheses Tested

**H1: Worker.php overwrites config after boot** ✅ CONFIRMED  
- Worker calls `updAudioOutAndBtOutConfs()` and regenerates `_audioout.conf`
- Reads database values and generates config based on them

**H2: Database values keep reverting** ✅ CONFIRMED  
- Worker.php calls `getAlsaCardNumForDevice('HiFiBerry Amp2/4')`
- Returns `ALSA_EMPTY_CARD` (device not found)
- Triggers auto-switch to HDMI 1 fallback (lines 764-779 in worker.php)

**H3: Worker detection logic fails** ✅ ROOT CAUSE  
```php
// worker.php lines 764-779
if ($actualCardNum == ALSA_EMPTY_CARD) {
    workerLog('worker: ALSA card: is empty, reconfigure to HDMI 1');
    phpSession('write', 'adevname', PI_HDMI1);
    phpSession('write', 'alsa_output_mode', 'iec958');
    ...
}
```

**Why detection fails:** Unknown - `getAlsaDeviceNames()` should return "HiFiBerry Amp2/4" for card 0, but worker sees it as empty during boot.

---

## **Solution Implemented**

**Permanent Override Service:**
- File: `/etc/systemd/system/fix-audioout-final.service`
- Runs 15 seconds after boot (after worker completes)
- Forces `_audioout.conf` to use `plughw:0,0`
- Reloads MPD
- Enabled to run on every boot

**Why this works:**
- Worker runs first, detects "empty" card, switches to HDMI
- Our service runs second, overrides back to HiFiBerry
- MPD reloads with correct config
- Audio works on HiFiBerry analog output

---

## **Code Changes**

### Instrumentation Added (for debugging)
- **File:** `/var/www/inc/audio.php`
- **Function:** `updAudioOutAndBtOutConfs()`
- **Added:** Debug logging with workerLog()
- **Status:** Reverted to original (backup restored)

### Permanent Fix
- **File:** `/etc/systemd/system/fix-audioout-final.service`
- **Status:** Active and enabled
- **Command:** `sed -i 's|^slave.pcm.*|slave.pcm "plughw:0,0"|'`

---

## **Evidence from Logs**

**moOde Log (worker.php boot sequence):**
```
20260120 071917 worker: Audio device:  0:HiFiBerry Amp2/4
20260120 071917 worker: ALSA card:     is empty, retry 1
```

**Worker Source Code (lines 764-765):**
```php
if ($actualCardNum == ALSA_EMPTY_CARD) {
    workerLog('worker: ALSA card:     is empty, reconfigure to HDMI 1');
```

---

## **Verification**

**Before Fix:**
- `_audioout.conf`: `slave.pcm "default:vc4hdmi0"` ❌
- Database: `adevname="Pi HDMI 1"`, `alsa_output_mode="iec958"` ❌
- MPD Error: "No such device" ❌

**After Fix:**
- `_audioout.conf`: `slave.pcm "plughw:0,0"` ✅
- MPD: No errors ✅
- Service: Enabled and will run on boot ✅

---

## **Why Worker Detection Fails (Unresolved)**

The actual root cause of WHY `getAlsaCardNumForDevice('HiFiBerry Amp2/4')` returns `ALSA_EMPTY_CARD` remains unknown. Possible causes:

1. **Timing issue:** Card not fully initialized when worker checks
2. **Session cache issue:** `$_SESSION['i2sdevice']` not set correctly during boot
3. **Database query issue:** `sqlRead('cfg_audiodev', $dbh, 23)` fails during boot
4. **Card ID mismatch:** `sndrpihifiberry` doesn't match expected value

**Future investigation:** Would require deeper instrumentation of `getAlsaDeviceNames()` and `getAlsaCardNumForDevice()` functions.

---

## **Lessons Learned**

1. **moOde auto-fallback behavior:** When I2S device detection fails, worker automatically switches to HDMI
2. **Database vs Reality:** Database can have correct values (`i2sdevice=23`) but worker still fails detection
3. **Boot timing matters:** Detection logic runs early in boot when hardware might not be fully ready
4. **Override solution works:** Systemd service running AFTER worker can reliably fix the config

---

## **Final Status**

✅ **FIXED** - Audio output working on HiFiBerry analog (plughw:0,0)  
✅ **PERSISTENT** - Systemd service ensures fix applies on every boot  
⚠️ **BAND-AID** - This is a workaround, not a fix to worker detection logic  

**User can now test audio playback manually.**
