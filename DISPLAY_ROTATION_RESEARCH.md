# Display Rotation Research - Moode Audio & PeppyMeter

**Date:** 2025-12-25  
**Purpose:** Understand how Moode Audio and PeppyMeter handle display rotation, and identify common issues and solutions.

---

## Key Findings

### 1. Moode Audio Display Rotation Logic

**Location:** `/home/andre/.xinitrc`

**How it works:**
```bash
# Reads orientation from Moode database
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")

# For HDMI screens (default is landscape)
if [ $HDMI_SCN_ORIENT = "portrait" ]; then
    SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')  # Swap dimensions
    DISPLAY=:0 xrandr --output HDMI-1 --rotate left
fi
```

**Key Points:**
- Moode assumes HDMI displays are **landscape by default**
- Only rotates if `hdmi_scn_orient=portrait` in database
- Uses `xrandr --rotate left` for portrait mode
- Swaps `SCREEN_RES` dimensions when rotating

**Problem Identified:**
- Display hardware reports `400x1280` (portrait) initially
- If Moode setting is `landscape`, no rotation is applied
- But physical display needs rotation to show `1280x400` correctly
- This creates a mismatch: software thinks landscape, hardware reports portrait

---

### 2. PeppyMeter Display Detection

**Location:** `/opt/peppymeter/`

**How it works:**
1. **Folder Name Convention:** `WIDTHxHEIGHT-any_text`
   - Example: `1280x400` folder → width=1280, height=400
   - Parsed by `get_meter_size()` function in `configfileparser.py`

2. **Screen Size Detection:**
   ```python
   def get_meter_size(self, meter_folder):
       """ Get meter size from the meter folder name using convention:
       480x320-any_text, where 480-meter width, 320-meter height
       """
       # Parses folder name to extract WIDTHxHEIGHT
       return (int(w), int(h))
   ```

3. **Pygame Display Initialization:**
   ```python
   # Uses dimensions from config/folder name
   self.util.PYGAME_SCREEN = pygame.display.set_mode((screen_w, screen_h))
   ```

4. **Config File Settings:**
   - `SCREEN_WIDTH` and `SCREEN_HEIGHT` can be set in config
   - Falls back to folder name parsing if not set

**Current State (Verified):**
- Pygame reports: `current_w = 1280, current_h = 400` ✅
- Available modes: `[(1280, 400), (720, 1280)]`
- Display is correctly rotated to landscape

**Key Points:**
- PeppyMeter uses **folder name** to determine screen size
- Does NOT query X11/xrandr for actual display dimensions
- Relies on correct folder name matching actual display size
- Uses pygame's `set_mode()` with those dimensions

---

### 3. Common Problems & Solutions

#### Problem 1: Display Reports Wrong Orientation
**Symptom:** Display hardware reports `400x1280` but should be `1280x400`

**Root Cause:**
- Display EDID reports portrait mode
- Or display hardware is physically rotated
- Or `config.txt`/`cmdline.txt` has wrong video parameters

**Solutions Found:**
1. **Force rotation in `config.txt`:**
   ```ini
   [all]
   display_rotate=0  # No rotation at boot level
   hdmi_mode=87
   hdmi_cvt 1280 400 60 6 0 0 0
   ```

2. **Force rotation in `cmdline.txt`:**
   ```
   video=HDMI-A-2:1280x400M@60
   ```

3. **Force rotation in `.xinitrc` BEFORE PeppyMeter:**
   ```bash
   # Fix display orientation BEFORE PeppyMeter starts
   if [ $PEPPY_SHOW = "1" ]; then
       /usr/local/bin/fix-display-orientation-before-peppy.sh
       sleep 1
   fi
   ```

#### Problem 2: Moode Setting vs Reality Mismatch
**Symptom:** Setting `landscape` in Moode makes display show `portrait` in reality

**Root Cause:**
- Moode's `.xinitrc` only rotates if `hdmi_scn_orient=portrait`
- If set to `landscape`, no rotation is applied
- But display hardware needs rotation to show correct orientation

**Solution:**
- Always apply rotation fix BEFORE PeppyMeter starts
- Don't rely solely on Moode's `hdmi_scn_orient` setting
- Check actual display dimensions and rotate if needed

#### Problem 3: PeppyMeter Uses Wrong Dimensions
**Symptom:** Meters are wrong size or positioned incorrectly

**Root Cause:**
- PeppyMeter uses folder name (`1280x400`) for screen size
- If display is actually `400x1280`, meters will be wrong size

**Solution:**
- Ensure display is rotated to correct orientation BEFORE PeppyMeter starts
- Use correct folder name matching actual display dimensions
- Verify with `pygame.display.Info()` that dimensions match

---

## Recommended Approach

### 1. Fix Display Orientation BEFORE PeppyMeter Starts

**Script:** `/usr/local/bin/fix-display-orientation-before-peppy.sh`

**Purpose:**
- Detects actual display dimensions
- Rotates to `1280x400` if needed
- Verifies correct orientation
- Runs BEFORE PeppyMeter starts (from `.xinitrc`)

**Integration:**
```bash
# In .xinitrc, before PeppyMeter launch:
if [ $PEPPY_SHOW = "1" ]; then
    /usr/local/bin/fix-display-orientation-before-peppy.sh
    sleep 1
fi
```

### 2. Ensure Moode Database Setting Matches Reality

**Setting:** `hdmi_scn_orient` in Moode database

**Action:**
- Set to `landscape` if display should be `1280x400`
- But don't rely on Moode's rotation logic alone
- Always apply explicit rotation fix before PeppyMeter

### 3. Use Correct PeppyMeter Folder

**Folder:** `/opt/peppymeter/1280x400/`

**Ensure:**
- Folder name matches actual display dimensions after rotation
- Config file (`meters.txt`) uses correct coordinates
- Meter images fit the display size

---

## Forum & Repository References

### Moode Audio
- **Forum:** moodeaudio.org (search for "display rotation", "portrait landscape")
- **Key Setting:** `hdmi_scn_orient` in database
- **Rotation Logic:** Only rotates if `portrait` setting

### PeppyMeter
- **Repository:** github.com/project-owner/PeppyMeter
- **Integration Guide:** github.com/FdeAlexa/PeppyMeter_and_moOde
- **Screen Detection:** Uses folder name convention `WIDTHxHEIGHT`
- **Latest Edition:** Picasso Edition 2024.02.10

### Common Issues
- Display reports wrong orientation (EDID issue)
- Moode setting doesn't match reality
- PeppyMeter uses wrong dimensions
- Rotation applied too late (after PeppyMeter starts)

---

## Current Implementation Status

✅ **Display Fix Script:** Created and integrated into `.xinitrc`  
✅ **PeppyMeter Config:** Configured for `1280x400` landscape  
✅ **Display Rotation:** Working (pygame reports `1280x400`)  
✅ **Meter Sizing:** Meters properly sized and positioned  

**Next Steps:**
1. Verify display fix runs before PeppyMeter on every boot
2. Test that rotation persists across reboots
3. Ensure Moode database setting matches reality
4. Monitor for any display orientation issues

---

## Key Takeaways

1. **Moode's rotation logic is conditional** - only rotates if `portrait` setting
2. **PeppyMeter uses folder name for screen size** - doesn't query X11
3. **Display hardware may report wrong orientation** - needs explicit rotation
4. **Rotation must happen BEFORE PeppyMeter starts** - otherwise wrong dimensions
5. **Always verify with pygame/pygame.display.Info()** - confirms actual dimensions

---

**Status:** ✅ Research complete - Display rotation mechanism understood, fix implemented

