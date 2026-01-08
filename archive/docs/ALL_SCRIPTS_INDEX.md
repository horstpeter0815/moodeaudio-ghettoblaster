# All Scripts Index - Touchscreen Fix

**Complete list of all scripts and what they do**

---

## MAIN FIX SCRIPT

### `fix_everything.sh` ⭐ **USE THIS**
- **Purpose:** Complete fix for all issues
- **What it does:**
  - Removes video parameter workaround
  - Fixes config.txt
  - Fixes xinitrc
  - Configures touchscreen
  - Creates backups
- **Usage:** `./fix_everything.sh`
- **Then:** `sudo reboot`

### `fix_everything_improved.sh`
- **Purpose:** Improved version with auto-detection
- **Improvements:**
  - Auto-detects HDMI port
  - Handles /boot vs /boot/firmware
  - More robust error handling
- **Usage:** `./fix_everything_improved.sh`

---

## VERIFICATION SCRIPTS

### `verify_everything.sh` ⭐ **VERIFY WITH THIS**
- **Purpose:** Complete system verification
- **Checks:**
  - cmdline.txt (no video parameter)
  - config.txt (display_rotate=0)
  - xinitrc (no forced rotation)
  - Display resolution
  - Touchscreen configuration
- **Usage:** `./verify_everything.sh`
- **Output:** ✅ All checks passed or ❌ Errors found

### `verify_touchscreen.sh`
- **Purpose:** Touchscreen-specific verification
- **Checks:**
  - USB device detection
  - Input device
  - X11 integration
  - Transformation matrix
- **Usage:** `./verify_touchscreen.sh`

---

## TEST SCRIPTS

### `test_touchscreen.sh` ⭐ **TEST TOUCHSCREEN**
- **Purpose:** Test touchscreen coordinates
- **What it does:**
  - Finds touchscreen device
  - Shows current properties
  - Tests touch input
- **Usage:** `./test_touchscreen.sh`
- **Then:** Touch screen corners, verify coordinates

### `test_display_resolution.sh`
- **Purpose:** Test display resolution
- **What it does:**
  - Checks xrandr output
  - Checks framebuffer
  - Verifies no rotation workaround
- **Usage:** `./test_display_resolution.sh`

### `test_peppy_requirements.sh` ⭐ **TEST PEPPY**
- **Purpose:** Test Peppy Meter requirements
- **What it does:**
  - Checks display resolution
  - Checks orientation
  - Checks touchscreen
  - Verifies all requirements
- **Usage:** `./test_peppy_requirements.sh`

### `complete_test_suite.sh`
- **Purpose:** Run all tests
- **Usage:** `./complete_test_suite.sh`

---

## TOUCHSCREEN SCRIPTS

### `setup_touchscreen.sh`
- **Purpose:** Initial touchscreen setup
- **Usage:** `./setup_touchscreen.sh`

### `fix_touchscreen_complete.sh`
- **Purpose:** Complete touchscreen fix
- **Usage:** `./fix_touchscreen_complete.sh`

### `fix_touchscreen_coordinates.sh` ⭐ **CALIBRATE COORDINATES**
- **Purpose:** Interactive coordinate calibration
- **What it does:**
  - Tests current coordinates
  - Offers transformation matrices
  - Applies and saves configuration
- **Usage:** `./fix_touchscreen_coordinates.sh`
- **When:** If coordinates are wrong after fix

---

## DIAGNOSTIC SCRIPTS

### `diagnose_pi5.sh`
- **Purpose:** Gather system information
- **Usage:** `./diagnose_pi5.sh > diagnostic_output.txt`

---

## QUICK START WORKFLOW

### Step 1: Fix Everything
```bash
./fix_everything.sh
```

### Step 2: Reboot
```bash
sudo reboot
```

### Step 3: Verify
```bash
./verify_everything.sh
```

### Step 4: Test
```bash
./test_touchscreen.sh
./test_peppy_requirements.sh
```

### Step 5: If Coordinates Wrong
```bash
./fix_touchscreen_coordinates.sh
```

---

## SUCCESS CHECKLIST

After running scripts:

- [ ] `./verify_everything.sh` shows all ✅
- [ ] `./test_touchscreen.sh` - coordinates correct
- [ ] `./test_peppy_requirements.sh` - all requirements met
- [ ] Chromium works
- [ ] Peppy Meter works
- [ ] Touch works everywhere

---

**All scripts ready. Run them. Verify. Make it work.**

