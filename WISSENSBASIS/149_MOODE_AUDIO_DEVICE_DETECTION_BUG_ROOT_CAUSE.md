# moOde Audio Device Detection Bug - Complete Root Cause Analysis

**Date:** 2026-01-20  
**Symptoms:** "Failed to open audio output", MPD can't play, CamillaDSP not running  
**Status:** Root cause identified through deep code reading

## Symptom Chain

1. MPD logs: `Failed to play on "ALSA Default" (alsa): snd_pcm_poll_descriptors_revents() failed: No such device`
2. CamillaDSP: `ERROR [src/bin.rs:939] Invalid config file!`
3. CamillaDSP service: `inactive (dead)` - not running
4. Database shows: `cardnum='empty'`, `adevname='Pi HDMI 1'`, `alsa_output_mode='iec958'`
5. `_audioout.conf` points to `camilladsp` but device doesn't exist

## Complete Root Cause Chain

### 1. **Session Initialization Order Bug**

**File:** `/var/www/inc/alsa.php`  
**Function:** `getAlsaDeviceNames()` line 121-177

```php
// Line 146: Look up card ID in cfg_audiodev
$result = sqlRead('cfg_audiodev', $dbh, $cardID);

if ($result === true) {
    // Not found: check if I2S device
    if (isUSBDevice($i)) {
        $deviceNames[$i] = $aplayDeviceName;
    } else {
        // Line 159: I2S DEVICE - DEPENDS ON SESSION!
        $result = sqlRead('cfg_audiodev', $dbh, $_SESSION['i2sdevice']);
        if ($result === true) {
            $deviceNames[$i] = $aplayDeviceName;
        } else {
            // Line 165: Uses name from cfg_audiodev
            $deviceNames[$i] = $result[0]['name'];
        }
    }
}
```

**The Bug:**
- HiFiBerry card ID is `sndrpihifiberry`
- This ID is **NOT in `cfg_audiodev` table** (only the device ID `23` is)
- Code falls through to line 159: `sqlRead('cfg_audiodev', $dbh, $_SESSION['i2sdevice'])`
- But **`$_SESSION['i2sdevice']` is NOT initialized** during boot!
- sqlRead with NULL/empty parameter returns wrong device (e.g., "Allo Boss 2 DAC")

**Evidence:**
```bash
# Runtime test shows:
Session i2sdevice: NOT SET
Device names array:
    [0] => Allo Boss 2 DAC   ← WRONG! Should be "HiFiBerry Amp2/4"
```

### 2. **ALSA_EMPTY_CARD Detection Failure**

**File:** `/var/www/daemon/worker.php` lines 754-764

```php
for ($i = 0; $i < $maxLoops; $i++) {
    $actualCardNum = getAlsaCardNumForDevice($_SESSION['adevname']);
    if ($actualCardNum == ALSA_EMPTY_CARD) {
        workerLog('worker: ALSA card:     is empty, retry ' . ($i + 1));
        sleep($sleepTime);
    } else {
        break;
    }
}
```

**What Happens:**
1. Database says: `adevname='HiFiBerry Amp2/4'`
2. But `getAlsaDeviceNames()[0]` returns "Allo Boss 2 DAC" (due to session bug)
3. `getAlsaCardNumForDevice('HiFiBerry Amp2/4')` searches for it in array
4. Not found → returns `ALSA_EMPTY_CARD` (string "empty")
5. Retries 12 times (1 minute), always fails
6. Falls through to HDMI reconfiguration

### 3. **Database Reset to HDMI**

**File:** `/var/www/daemon/worker.php` lines 764-779

```php
if ($actualCardNum == ALSA_EMPTY_CARD) {
    workerLog('worker: ALSA card:     is empty, reconfigure to HDMI 1');
    $hdmi1CardNum = getAlsaCardNumForDevice(PI_HDMI1);
    // Update configuration
    phpSession('write', 'adevname', PI_HDMI1);
    phpSession('write', 'cardnum', $hdmi1CardNum);
    phpSession('write', 'alsa_output_mode', 'iec958');
}
```

**Result:**
- `adevname` → "Pi HDMI 1"
- `cardnum` → "empty" (HDMI also not found!)
- `alsa_output_mode` → "iec958" (HDMI mode)

### 4. **CamillaDSP Gets Wrong Device**

**File:** `/var/www/inc/cdsp.php` lines 55-77

```php
function setPlaybackDevice($cardNum, $outputMode = 'plughw') {
    if ($_SESSION['peppy_display'] == '1') {
        $alsaDevice = 'peppy';
    } else if ($_SESSION['audioout'] == 'Bluetooth') {
        $alsaDevice = 'btstream';
    } else {
        // Line 63: outputMode='iec958' → returns HDMI device!
        $alsaDevice = $outputMode == 'iec958' ? getAlsaIEC958Device() : 
            $outputMode . ':' . $cardNum . ',0';
    }
    
    $ymlCfg['devices']['playback'] = Array(
        'type' => 'Alsa',
        'channels' => 2,
        'device' => $alsaDevice,  // ← Gets HDMI device!
        'format' => $useFormat
    );
}
```

**Result in CamillaDSP YAML:**
```yaml
playback:
  type: Alsa
  device: default:vc4hdmi0  # ← HDMI, not HiFiBerry!
```

### 5. **CamillaDSP Fails to Start**

```
ERROR [src/bin.rs:939] Invalid config file!
```

CamillaDSP tries to open HDMI device, fails, service stays inactive/dead.

### 6. **MPD Can't Open Audio Output**

1. MPD config: `device "_audioout"`
2. `/etc/alsa/conf.d/_audioout.conf`: `slave.pcm "camilladsp"`
3. But `camilladsp` ALSA device doesn't exist (service not running)
4. MPD: `Failed to open audio output: No such device`

## Why The Fix Service Doesn't Work

**Service:** `fix-audioout-cdsp.service`

The service runs and updates the database:
```bash
UPDATE cfg_system SET value='HiFiBerry Amp2/4' WHERE param='adevname';
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
UPDATE cfg_system SET value='0' WHERE param='cardnum';
```

**But:**
1. Runs at boot after 15-second delay
2. By that time, worker.php already reset values to HDMI
3. Even if database is fixed, CamillaDSP YAML still has wrong device
4. CamillaDSP needs to be reconfigured AND restarted
5. And the session initialization bug remains

## The Real Fix

**Problem:** `getAlsaDeviceNames()` depends on `$_SESSION['i2sdevice']` being set, but session isn't initialized early enough during boot.

**Solution Options:**

### Option 1: Initialize Session Earlier
Ensure `$_SESSION['i2sdevice']` is loaded before ANY audio configuration code runs.

### Option 2: Make getAlsaDeviceNames() Session-Independent
Modify the function to query database directly instead of relying on session:

```php
// Line 159: Instead of using $_SESSION['i2sdevice']
// Query database to find which I2S device is configured
$i2sDevice = sqlQuery("SELECT value FROM cfg_system WHERE param='i2sdevice'", $dbh)[0]['value'];
$result = sqlRead('cfg_audiodev', $dbh, $i2sDevice);
```

### Option 3: Add Card ID Mapping to cfg_audiodev
Add an entry in `cfg_audiodev` table:
```sql
INSERT INTO cfg_audiodev (id, name, alt_name, ...) 
VALUES ('sndrpihifiberry', 'HiFiBerry Amp2/4', 'HiFiBerry Amp2/4', ...);
```

So the lookup at line 146 succeeds without needing session.

### Option 4: Better Error Handling in getAlsaDeviceNames()
```php
// Line 159: Check if session variable is set
if (!isset($_SESSION['i2sdevice']) || empty($_SESSION['i2sdevice'])) {
    // Fallback: query database directly
    $i2sDevice = sqlQuery("SELECT value FROM cfg_system WHERE param='i2sdevice'", $dbh)[0]['value'];
    $result = sqlRead('cfg_audiodev', $dbh, $i2sDevice);
} else {
    $result = sqlRead('cfg_audiodev', $dbh, $_SESSION['i2sdevice']);
}
```

## Lessons Learned

1. **Hidden Dependencies:** `getAlsaDeviceNames()` looks like a pure utility function but has hidden session dependency
2. **Initialization Order:** Session must be initialized before audio detection code runs
3. **Error Propagation:** One small bug (session not set) cascades through entire audio stack
4. **Retry Logic:** Worker retries 12 times but never fixes the root cause
5. **Database as Source of Truth:** Multiple code paths expect database to be correct, but worker.php can overwrite it

## Related Issues

- **ALSA_EMPTY_CARD bug:** Documented in `WISSENSBASIS/144_MOODE_WORKER_AUDIO_DETECTION_BUG.md`
- **CamillaDSP integration:** Device selection logic in `audio.php::updDspAndBtInConfs()`
- **Session management:** How moOde initializes and maintains session state

## Recommendations

1. **Immediate:** Implement Option 2 or 4 to make `getAlsaDeviceNames()` session-independent
2. **Short-term:** Add better error logging when session variables are missing
3. **Long-term:** Refactor audio detection to have clear initialization order
4. **Testing:** Create unit tests for `getAlsaDeviceNames()` with and without session

## Status

- [x] Root cause identified
- [x] Code path traced completely
- [x] Bug mechanism understood
- [ ] Fix implemented
- [ ] Fix tested
- [ ] Fix committed
