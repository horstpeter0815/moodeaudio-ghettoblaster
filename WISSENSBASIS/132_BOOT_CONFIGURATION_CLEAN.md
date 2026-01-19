# Boot Configuration - Clean Boot & Orientation

**Date:** 2026-01-19  
**Status:** ✅ Configured for custom build

## User Requirements

1. **No Raspberry Pi logos/rainbows on boot** - Only text prompts
2. **Boot prompt orientation** - Landscape (1280x400)
3. **moOde WebUI orientation** - Landscape (1280x400)
4. **Consistent orientation** - Both boot and runtime in landscape

---

## Configuration Files

### 1. cmdline.txt (Kernel Boot Parameters)

**Script:** `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh`

**Parameters:**
```bash
console=tty3 root=... rootwait quiet loglevel=3 logo.nologo vt.global_cursor_default=0 video=HDMI-A-1:400x1280M@60,rotate=90
```

#### Parameter Breakdown

| Parameter | Purpose |
|-----------|---------|
| `console=tty3` | Boot messages go to tty3 (not visible, only prompts on tty1) |
| `quiet` | Suppress non-critical boot messages |
| `loglevel=3` | Only show errors (3=ERR, not 7=DEBUG) |
| `logo.nologo` | **Removes Tux penguin logo** |
| `vt.global_cursor_default=0` | **Removes blinking cursor** |
| `video=HDMI-A-1:400x1280M@60,rotate=90` | **Sets display to landscape at kernel level** |

**Result:** Clean boot, no logos, landscape orientation from the start ✅

---

### 2. config.txt (Raspberry Pi Firmware Config)

**File:** `moode-source/boot/firmware/config.txt.overwrite`

**Critical Settings:**
```ini
# Remove Raspberry Pi rainbow splash screen
disable_splash=1

# Let EDID auto-detect display (DO NOT override with hdmi_group=2)
# hdmi_group=0 is implicit (auto-detect)
# NO hdmi_mode=87 or custom hdmi_timings

# Audio settings
arm_boost=1
hdmi_blanking=1
hdmi_force_edid_audio=1
hdmi_force_hotplug=1
dtparam=audio=off
```

**Result:** No rainbow screen, auto-detect display ✅

---

## What the User Sees

### Boot Sequence

1. **Power on** → Black screen (no rainbow!)
2. **Kernel messages** → Only critical prompts (quiet mode)
3. **Login prompt** → Clean text, landscape orientation
4. **X11 starts** → moOde WebUI loads in landscape
5. **Result** → Seamless landscape experience, no Raspberry Pi branding

### What's Hidden

- ❌ Rainbow splash screen (`disable_splash=1`)
- ❌ Raspberry Pi logos (`logo.nologo`)
- ❌ Tux penguin logo (`logo.nologo`)
- ❌ Boot messages (`quiet loglevel=3 console=tty3`)
- ❌ Blinking cursor (`vt.global_cursor_default=0`)

### What's Visible

- ✅ Only essential prompts (errors, warnings)
- ✅ Login prompt (if not auto-login)
- ✅ moOde WebUI in landscape

---

## Orientation Consistency

### How It Works Together

1. **Kernel Level (cmdline.txt)**
   - `video=HDMI-A-1:400x1280M@60,rotate=90`
   - Physical display: 400x1280 (portrait)
   - Rotated to: 1280x400 (landscape)
   - This affects BOTH console and X11

2. **X11 Level (.xinitrc)**
   - Reads moOde database: `hdmi_scn_orient`
   - If `landscape`: Uses rotated framebuffer as-is
   - If `portrait`: Rotates back to 400x1280

3. **moOde Database**
   - `cfg_system.hdmi_scn_orient = 'landscape'`
   - This matches the kernel rotation
   - Result: Consistent landscape orientation

### Why It Works

- **cmdline.txt** sets the BASE orientation (landscape)
- **X11/.xinitrc** reads the database and applies rotation if needed
- **Database** controls the final orientation
- **config.txt** auto-detects display, doesn't override

**Critical:** config.txt does NOT use `hdmi_group=2` or `hdmi_mode=87` because these cause Chromium to use the wrong framebuffer size. We let EDID auto-detect the display, and rotation is handled by `cmdline.txt` video parameter.

---

## Verification After Build

```bash
# 1. Check cmdline.txt has correct parameters
cat /boot/firmware/cmdline.txt | grep -E "quiet|logo.nologo|video=|console=tty3"

# 2. Check config.txt has disable_splash=1
grep disable_splash /boot/firmware/config.txt

# 3. Check config.txt does NOT have hdmi_group=2 (should be 0 or absent)
grep hdmi_group /boot/firmware/config.txt

# 4. Check orientation is landscape
moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'"
# Expected: landscape

# 5. Test boot sequence
sudo reboot
# Watch for: No rainbow, no logos, clean boot, landscape orientation
```

---

## Common Issues and Fixes

### Issue: Rainbow screen appears

**Cause:** `disable_splash=1` not in config.txt  
**Fix:** Add to config.txt:
```bash
echo "disable_splash=1" >> /boot/firmware/config.txt
```

### Issue: Boot messages flood screen

**Cause:** Missing `quiet loglevel=3 console=tty3` in cmdline.txt  
**Fix:** Edit cmdline.txt to include these parameters

### Issue: Chromium wrong size (10x10 or black screen)

**Cause:** `hdmi_group=2`, `hdmi_mode=87`, or custom `hdmi_timings` in config.txt  
**Fix:** Remove these lines, let EDID auto-detect (hdmi_group=0)

### Issue: Boot in portrait, moOde in landscape (or vice versa)

**Cause:** Mismatch between cmdline.txt rotation and database setting  
**Fix:** Ensure both are consistent:
- cmdline.txt: `video=HDMI-A-1:400x1280M@60,rotate=90` (landscape)
- Database: `hdmi_scn_orient='landscape'`

---

## Summary

✅ **Clean boot** - No Raspberry Pi branding, only prompts  
✅ **Landscape orientation** - Consistent from boot to moOde WebUI  
✅ **No logos** - Rainbow splash disabled, Tux penguin removed  
✅ **Quiet boot** - Only critical messages, no flood  
✅ **Cursor hidden** - No blinking cursor on boot  

**Result:** Professional boot experience, seamless landscape display! 🎉
