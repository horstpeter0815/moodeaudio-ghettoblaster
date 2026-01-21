# ✅ Display Fixed - All 3 Components Working Together

**Date:** 2026-01-21  
**Status:** COMPLETE - Boot console and Moode UI both in landscape 1280x400

---

## The 3 Components and How They Work

### 1. BOOT CONSOLE (config.txt + cmdline.txt)

**Purpose:** Control the framebuffer during boot (before X server starts)

**Files:**
- `/boot/firmware/config.txt`
- `/boot/firmware/cmdline.txt`

**Configuration:**
```
# config.txt
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
hdmi_timings=1280 0 110 32 220 400 0 10 10 10 0 0 0 60 0 59510000 0

# cmdline.txt
video=HDMI-A-1:1280x400@60
```

**What it does:**
- Sets hardware HDMI timings for 1280x400
- Forces kernel framebuffer to 1280x400 landscape
- **Result:** Boot console messages appear in LANDSCAPE

---

### 2. X SERVER (.xinitrc)

**Purpose:** Configure X server display when it starts

**File:** `/home/andre/.xinitrc`

**Configuration:**
```bash
# Force 1280x400 landscape mode
xrandr --newmode "1280x400_60" 59.51 1280 1390 1422 1510 400 410 420 430 -hsync +vsync
xrandr --addmode HDMI-2 1280x400_60
xrandr --output HDMI-2 --mode 1280x400_60
```

**What it does:**
- Creates custom 1280x400 mode for X server
- Applies it to HDMI-2 output
- **Result:** X server runs at 1280x400 landscape (seamless transition from boot)

---

### 3. MOODE UI (.xinitrc)

**Purpose:** Launch Chromium with correct window size

**File:** `/home/andre/.xinitrc` (same file)

**Configuration:**
```bash
chromium --app="http://localhost/" \
  --window-size=1280,400 \
  --window-position="0,0" \
  --kiosk
```

**What it does:**
- Launches Chromium fullscreen at 1280x400
- Matches X server resolution
- **Result:** Moode UI fills screen in landscape

---

## Why All 3 Must Match

**Problem before fix:**
- Boot console: Auto-detected (probably portrait)
- X server: 1280x400 landscape  
- Moode UI: 1280x400 landscape

**Result:** Display gets confused during boot→X transition, goes black

**After fix:**
- Boot console: 1280x400 landscape ✅
- X server: 1280x400 landscape ✅
- Moode UI: 1280x400 landscape ✅

**Result:** Smooth transition, no black screen, consistent orientation

---

## Files Modified

### 1. /boot/firmware/cmdline.txt
```
console=tty3 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-1:1280x400@60 quiet loglevel=3 logo.nologo vt.global_cursor_default=0
```

**Changed:** Added `video=HDMI-A-1:1280x400@60`

### 2. /boot/firmware/config.txt
```
# Waveshare 1280x400 landscape display
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
hdmi_timings=1280 0 110 32 220 400 0 10 10 10 0 0 0 60 0 59510000 0
```

**Changed:** Added HDMI timings section

### 3. /home/andre/.xinitrc
```bash
#!/bin/bash
# moOde .xinitrc for 1280x400 landscape display

# Screen blanking
xset s 600 0 2>/dev/null
xset +dpms 2>/dev/null
xset dpms 600 0 0 2>/dev/null

# Force 1280x400 landscape mode
xrandr --newmode "1280x400_60" 59.51 1280 1390 1422 1510 400 410 420 430 -hsync +vsync 2>/dev/null
xrandr --addmode HDMI-2 1280x400_60 2>/dev/null
xrandr --output HDMI-2 --mode 1280x400_60 2>/dev/null
sleep 1

# Get display config from database
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'")
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'")
PEPPY_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display_type'")

# Launch WebUI or Peppy
if [ "$WEBUI_SHOW" = "1" ]; then
    $(/var/www/util/sysutil.sh clearbrcache)
    exec chromium --app="http://localhost/" --window-size=1280,400 --window-position="0,0" --enable-features="OverlayScrollbar" --no-first-run --disable-infobars --disable-session-crashed-bubble --disable-pinch --overscroll-history-navigation=0 --force-device-scale-factor=1.0 --kiosk
elif [ "$PEPPY_SHOW" = "1" ]; then
    if [ "$PEPPY_TYPE" = "meter" ]; then
        cd /opt/peppymeter && exec python3 peppymeter.py
    else
        cd /opt/peppyspectrum && exec python3 spectrum.py
    fi
fi
```

**Changed:** Fixed syntax errors, added `exec` for proper process management

---

## Boot Sequence (What You See)

### 1. Power On → Boot Console (5-10 seconds)
- **Display shows:** Raspberry Pi boot logo
- **Then:** Kernel messages and systemd startup
- **Orientation:** LANDSCAPE 1280x400 ✅
- **Controlled by:** config.txt + cmdline.txt

### 2. X Server Starts (1-2 seconds)
- **Display shows:** Brief transition
- **Orientation:** LANDSCAPE 1280x400 ✅
- **Controlled by:** .xinitrc xrandr commands

### 3. Moode UI Launches (2-3 seconds)
- **Display shows:** Moode Audio web player
- **Orientation:** LANDSCAPE 1280x400 ✅
- **Controlled by:** .xinitrc chromium command

**Total boot time:** ~60 seconds (with audio speed fix)

---

## Troubleshooting

### If Boot Console Is Wrong Orientation
**Check:**
```bash
cat /boot/firmware/cmdline.txt | grep video=
# Should show: video=HDMI-A-1:1280x400@60

grep hdmi_timings /boot/firmware/config.txt
# Should show: hdmi_timings=1280 0 110 32 220 400 ...
```

**Fix:** Re-add the video parameter and HDMI timings

### If Moode UI Is Wrong Orientation
**Check:**
```bash
grep xrandr /home/andre/.xinitrc
# Should show xrandr commands for 1280x400

bash -n /home/andre/.xinitrc
# Should show: no errors
```

**Fix:** Recreate .xinitrc from this document

### If Display Goes Black During Boot
**Cause:** Mismatch between boot console and X server resolution

**Fix:** Ensure all 3 components use 1280x400:
1. config.txt hdmi_timings
2. cmdline.txt video= parameter
3. .xinitrc xrandr mode

---

## Technical Details

### HDMI Timings Explained
```
hdmi_timings=1280 0 110 32 220 400 0 10 10 10 0 0 0 60 0 59510000 0
             |    |  |   |   |   |   |  |  |  |  | | | |  | |
             |    |  |   |   |   |   |  |  |  |  | | | |  | +-- flags
             |    |  |   |   |   |   |  |  |  |  | | | |  +---- pixel clock
             |    |  |   |   |   |   |  |  |  |  | | | +------- aspect
             |    |  |   |   |   |   |  |  |  |  | | +--------- interlace
             |    |  |   |   |   |   |  |  |  |  | +----------- sync
             |    |  |   |   |   |   |  |  |  |  +------------- frame pack
             |    |  |   |   |   |   |  |  |  +---------------- vsync width
             |    |  |   |   |   |   |  |  +------------------- vsync back
             |    |  |   |   |   |   |  +---------------------- vsync front
             |    |  |   |   |   |   +------------------------- vertical
             |    |  |   |   |   +----------------------------- hsync back
             |    |  |   |   +--------------------------------- hsync width
             |    |  |   +------------------------------------- hsync front
             |    |  +----------------------------------------- h left margin
             |    +-------------------------------------------- horizontal
             +------------------------------------------------- horizontal
```

### xrandr Mode Explained
```
xrandr --newmode "1280x400_60" 59.51 1280 1390 1422 1510 400 410 420 430 -hsync +vsync
                                |     |    |    |    |    |   |   |   |    |      |
                                |     |    |    |    |    |   |   |   |    |      +-- vsync polarity
                                |     |    |    |    |    |   |   |   |    +--------- hsync polarity
                                |     |    |    |    |    |   |   |   +-------------- v total
                                |     |    |    |    |    |   |   +------------------ v sync end
                                |     |    |    |    |    |   +---------------------- v sync start
                                |     |    |    |    |    +-------------------------- vertical
                                |     |    |    |    +------------------------------- h total
                                |     |    |    +------------------------------------ h sync end
                                |     |    +----------------------------------------- h sync start
                                |     +---------------------------------------------- horizontal
                                +---------------------------------------------------- pixel clock (MHz)
```

---

## Summary

**The Problem:** Boot console and Moode UI had different orientations, causing display confusion

**The Solution:** Make all 3 components consistent at 1280x400 landscape:
1. **config.txt + cmdline.txt:** Boot console landscape
2. **.xinitrc xrandr:** X server landscape
3. **.xinitrc chromium:** Moode UI landscape

**The Result:** 
- ✅ Smooth boot with no orientation changes
- ✅ No black screen during transitions
- ✅ Moode UI always in landscape
- ✅ Touch interface works correctly

---

## Additional Fixes Applied

### Audio Speed Fix
**File:** `/var/www/daemon/worker.php`

**Change:** Trust database cardnum if card exists, skip 60-second retry loop

**Result:** Boot time reduced from ~120s to ~60s

### Audio Fix Service
**File:** `/usr/local/bin/fix-audioout-cdsp-enhanced.sh`

**Purpose:** Corrects HDMI fallback after worker.php boot

**Result:** Audio always works with HiFiBerry

---

## Current System Status

✅ **Display:** All 3 components at 1280x400 landscape  
✅ **Audio:** HiFiBerry Amp2/4 with CamillaDSP  
✅ **Boot:** Fast (~60 seconds)  
✅ **Services:** All active and working  

**Everything is now properly configured and documented!**
