# Display Configuration - All 3 Components

**Date:** 2026-01-21  
**Status:** Configured (awaiting physical verification)

---

## The 3 Components That Control Display

### 1. Boot Console (config.txt + cmdline.txt)

**File:** `/boot/firmware/config.txt`
```
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
hdmi_timings=1280 0 110 32 220 400 0 10 10 10 0 0 0 60 0 59510000 0
```

**File:** `/boot/firmware/cmdline.txt`
```
video=HDMI-A-1:1280x400@60
```

**Purpose:** Sets boot console to 1280×400 landscape

---

### 2. X Server (.xinitrc)

**File:** `/home/andre/.xinitrc`
```bash
# Force 1280x400 landscape mode
xrandr --newmode "1280x400_60" 59.51 1280 1390 1422 1510 400 410 420 430 -hsync +vsync
xrandr --addmode HDMI-2 1280x400_60
xrandr --output HDMI-2 --mode 1280x400_60
```

**Purpose:** X server uses 1280×400 landscape

---

### 3. Chromium Window (.xinitrc)

**File:** `/home/andre/.xinitrc`
```bash
chromium --window-size=1280,400
```

**Purpose:** Moode UI window matches resolution

---

## How They Work Together

```
BOOT:
├─ config.txt: Defines HDMI mode 87 (1280×400)
├─ cmdline.txt: Forces framebuffer video=1280x400
└─ Result: Console shows in landscape

X SERVER STARTS:
├─ .xinitrc runs
├─ xrandr creates 1280x400 mode
└─ Result: X display is landscape

CHROMIUM LAUNCHES:
├─ .xinitrc continues
├─ chromium starts with window-size=1280,400
└─ Result: Moode UI fills screen in landscape
```

---

## System Status (Software)

- ✅ X server: Running
- ✅ Chromium: Running with 1280×400
- ✅ Resolution: 1280×400 reported by xrandr
- ✅ Audio: HiFiBerry Amp2/4
- ✅ Boot speed: ~60 seconds (speed fix working)

---

## What You Should See

**During Boot:**
- Console messages in LANDSCAPE (1280×400)
- Text should be readable left-to-right

**After Boot:**
- Moode Audio web player
- LANDSCAPE orientation (1280×400)
- Touch interface working

---

## If You See Something Different

**If console is portrait:**
- config.txt or cmdline.txt not applied
- Needs reboot or SD card issue

**If Moode UI is portrait:**
- .xinitrc xrandr commands not working
- Display ignoring xrandr

**If black screen:**
- Display hardware issue
- Try unplug/replug HDMI
- Check display power

---

## Files Modified

```
/boot/firmware/cmdline.txt - Added video= parameter
/boot/firmware/config.txt - Added HDMI timings
/home/andre/.xinitrc - Fixed syntax, added xrandr
/var/www/daemon/worker.php - Speed fix (skip 60s retry)
```

---

## Next Steps

1. User reports what they ACTUALLY see on physical display
2. Troubleshoot based on real feedback
3. Don't assume it works - verify
