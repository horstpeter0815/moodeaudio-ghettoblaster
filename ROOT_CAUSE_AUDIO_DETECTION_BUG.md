# ROOT CAUSE: Audio Detection Bug

**Date:** 2026-01-21  
**Issue:** Worker.php always falls back to HDMI even when HiFiBerry is present  
**Status:** Root cause identified - proper fix needed

---

## The Problem

Worker.php consistently detects "ALSA card: is empty" for 12 retries (60 seconds), then falls back to "Pi HDMI 1" even when:
1. HiFiBerry card IS present and detected by ALSA (`card 0: sndrpihifiberry`)
2. Database has correct values (`adevname='HiFiBerry Amp2/4'`, `cardnum='0'`)
3. HDMI is disabled at device tree level (`dtoverlay=vc4-kms-v3d,noaudio,nohdmi`)

---

## Root Cause Analysis

### 1. Detection Flow
```
worker.php line 758:
  $actualCardNum = getAlsaCardNumForDevice($_SESSION['adevname']);
  ↓
alsa.php line 187:
  function getAlsaCardNumForDevice($deviceName) {
    $deviceNames = getAlsaDeviceNames();  // Returns array of device names
    $cardNum = getArrayIndex($deviceName, $deviceNames);  // Search for match
    return $cardNum;
  }
  ↓
  Returns ALSA_EMPTY_CARD if device not found in array
```

### 2. The Bug
`getAlsaDeviceNames()` returns an array where the device name **doesn't match** what's stored in the database:
- **Database has:** `'HiFiBerry Amp2/4'`
- **getAlsaDeviceNames() returns:** Something different (need to debug what exactly)
- **Result:** `getArrayIndex()` can't find a match, returns `ALSA_EMPTY_CARD`

### 3. Hardcoded HDMI Fallback
After 12 retries of "empty", worker.php **unconditionally** falls back to HDMI:

```php
// Line 768-779 in worker.php
if ($actualCardNum == ALSA_EMPTY_CARD) {
    workerLog('worker: ALSA card:     is empty, reconfigure to HDMI 1');
    $hdmi1CardNum = getAlsaCardNumForDevice(PI_HDMI1);
    // Update configuration
    phpSession('write', 'adevname', PI_HDMI1);
    phpSession('write', 'cardnum', $hdmi1CardNum);
    ...
}
```

**This happens EVEN IF:**
- HDMI is disabled in device tree
- HiFiBerry card is present
- Database has correct values

---

## Why Our Fixes Don't Work

### Fix #1: Session-Independent Detection (alsa.php)
**Status:** Deployed but ineffective  
**Why it fails:** The session detection fix helps read the database, but the fundamental problem is that `getAlsaDeviceNames()` returns a name that doesn't match the database value. Even with correct session values, the name comparison fails.

### Fix #2: Enhanced Fix Service
**Status:** Working as band-aid  
**Why it's needed:** After worker.php falls back to HDMI and corrupts the database, this service runs and corrects it. But it doesn't prevent the fallback from happening.

### Fix #3: WiFi Radio Enable
**Status:** Working  
**No relation to this bug**

### Fix #4: CamillaDSP v3 Syntax
**Status:** Working  
**No relation to this bug**

### Device Tree HDMI Disable
**Status:** Deployed but doesn't help  
**Why it fails:** Even with HDMI disabled at hardware level, worker.php still writes "Pi HDMI 1" to the database as a hardcoded fallback value. The code doesn't check if HDMI actually exists.

---

## The REAL Fix Needed

### Option 1: Fix getAlsaDeviceNames() Name Matching
**Location:** `/moode-source/www/inc/alsa.php` line 124-186

**Problem:** The device names returned by `getAlsaDeviceNames()` don't match what's in the database

**Solution:** Investigate what `getAlsaDeviceNames()` actually returns and ensure it matches the database values. This might involve:
1. Checking how I2S device names are determined (line 158-175)
2. Ensuring cfg_audiodev table has correct names
3. Making name comparison more robust (fuzzy matching?)

### Option 2: Remove HDMI Fallback When I2S Device Configured
**Location:** `/moode-source/www/daemon/worker.php` line 768-779

**Current Code:**
```php
if ($actualCardNum == ALSA_EMPTY_CARD) {
    workerLog('worker: ALSA card:     is empty, reconfigure to HDMI 1');
    $hdmi1CardNum = getAlsaCardNumForDevice(PI_HDMI1);
    ...
}
```

**Fixed Code:**
```php
if ($actualCardNum == ALSA_EMPTY_CARD) {
    // Check if an I2S device is configured
    if (!empty($_SESSION['i2sdevice']) && $_SESSION['i2sdevice'] != 'None') {
        // I2S device configured - don't fall back to HDMI
        // Keep trying or use card 0 as fallback
        workerLog('worker: ALSA card:     is empty but I2S device configured, using card 0');
        $_SESSION['cardnum'] = '0';
        $actualCardNum = 0;
    } else {
        // No I2S device - HDMI fallback is acceptable
        workerLog('worker: ALSA card:     is empty, reconfigure to HDMI 1');
        $hdmi1CardNum = getAlsaCardNumForDevice(PI_HDMI1);
        ...
    }
}
```

### Option 3: Trust the Database
**Location:** `/moode-source/www/daemon/worker.php` line 758-779

**Concept:** If database says `cardnum='0'` and `adevname='HiFiBerry Amp2/4'`, and ALSA shows card 0 exists, then **trust it** instead of searching for a name match.

**Implementation:**
```php
// Before the retry loop
$dbCardNum = $_SESSION['cardnum'];
$dbDevName = $_SESSION['adevname'];

// Check if the card number from database actually exists in ALSA
if ($dbCardNum !== 'empty' && alsaCardExists($dbCardNum)) {
    workerLog('worker: ALSA card:     using database value (card ' . $dbCardNum . ')');
    $actualCardNum = $dbCardNum;
} else {
    // Do the name-based detection as fallback
    $actualCardNum = getAlsaCardNumForDevice($_SESSION['adevname']);
    // ... existing retry loop ...
}

function alsaCardExists($cardNum) {
    $result = sysCmd('aplay -l | grep "card ' . $cardNum . ':"');
    return !empty($result);
}
```

---

## Current Workaround

**Enhanced fix service** runs at boot and after worker completes:
1. Detects HDMI fallback in database
2. Corrects to HiFiBerry values
3. Fixes ALSA config
4. Fixes CamillaDSP YAML

**Result:** Audio works but requires manual intervention after every boot where worker fails detection.

---

## Recommended Solution

**Implement Option 3 (Trust the Database)** because:
1. ✅ Least invasive - doesn't change name matching logic
2. ✅ Most robust - trusts user configuration
3. ✅ Handles updates - won't break on moOde updates that change device names
4. ✅ Fast - no retry loops if database is correct
5. ✅ Logical - if user configured HiFiBerry card 0, and card 0 exists, use it

**Fallback chain:**
1. Check if database cardnum exists in ALSA → use it
2. If not, try name-based detection → retry 12 times
3. If still empty AND no I2S device configured → HDMI fallback
4. If still empty AND I2S device configured → use card 0 anyway

---

## Why This Matters

Every boot:
1. Worker.php detects "empty" for 60 seconds (12 × 5 sec)
2. Falls back to HDMI (corrupts database)
3. Enhanced fix service corrects it (15 second delay + restart time)
4. Total delay: **~90 seconds** before audio works

With proper fix:
1. Worker.php trusts database (card 0 exists)
2. Audio works immediately
3. Total delay: **~30 seconds** (normal boot time)

---

## Testing the Proper Fix

1. Add `alsaCardExists()` function to `/moode-source/www/inc/alsa.php`
2. Modify detection logic in `/moode-source/www/daemon/worker.php` line 758
3. Test boot sequence
4. Verify worker.php logs show "using database value" instead of "is empty"
5. Confirm no HDMI fallback occurs
6. Test with HiFiBerry card unplugged (should fall back correctly)

---

## Current System State

**HDMI:** Disabled at device tree level (`dtoverlay=vc4-kms-v3d,noaudio,nohdmi`)  
**Database:** Correct after enhanced fix runs  
**Audio:** Working after manual fix  
**Worker detection:** Still broken (returns "empty")  
**Workaround:** Enhanced fix service corrects after boot  

**User impact:** Annoying 90-second delay, but system ultimately works.

---

## Conclusion

The audio detection bug is a **fundamental logic error** in worker.php:
- It searches for device name match instead of trusting database
- Name matching fails (returns "empty")
- Hardcoded HDMI fallback overwrites correct database values
- Even with HDMI disabled in hardware, code still writes "Pi HDMI 1"

**Proper fix:** Trust the database cardnum if that card exists in ALSA. This is future-proof and survives moOde updates.

**Current situation:** Using enhanced fix service as workaround until proper fix is implemented in moOde upstream.
