# Requirements and Conditions - Pi 5 HDMI Display System

**Date:** 2025-01-27  
**Focus:** HDMI Display (NOT DSI) - Stable, Future-Proof Solution

---

## HARDWARE SETUP

### Current Hardware:
- **Raspberry Pi 5 Model B Rev 1.1**
- **Waveshare 7.9" HDMI LCD Display** (1280x400 resolution)
- **OS:** Moode Audio (Debian 13 Trixie, Kernel 6.12.47+rpt-rpi-v8)
- **Display Connection:** HDMI (user can exchange DSI for HDMI)

---

## CURRENT STATE

### What's Working:
- ✅ HDMI display shows image
- ✅ Chromium browser displays Moode UI
- ✅ Display resolution: 1280x400 (Landscape)
- ✅ System boots and runs

### What's NOT Working (Workarounds in Use):
- ❌ Display must start in Portrait (400x1280) then rotate to Landscape
- ❌ Touchscreen doesn't work properly (coordinate issues)
- ❌ Peppy Meter doesn't work (expects correct orientation)
- ❌ Workarounds break other applications
- ❌ Not a clean, stable solution

### Current Workarounds:
1. **Portrait Start + Rotation:**
   - `video=HDMI-A-2:400x1280M@60,rotate=90` in cmdline.txt
   - `xrandr --output HDMI-2 --rotate left` in xinitrc
   
2. **Explicit Chromium Window Size:**
   - `--window-size="1280,400"` (hardcoded, ignores $SCREEN_RES)
   
3. **Double Rotation Logic:**
   - xinitrc always rotates, even if Moode says landscape

---

## REQUIREMENTS FOR STABLE SOLUTION

### 1. Display Requirements:
- ✅ **Resolution:** 1280x400 (Landscape)
- ✅ **Direct Landscape Start:** Display should start in Landscape, NOT Portrait
- ✅ **No Rotation Needed:** Should work without xrandr rotation workarounds
- ✅ **Touchscreen Support:** Must work correctly with proper coordinate mapping
- ✅ **Framebuffer:** Should report correct resolution (1280x400, not 400x1280)

### 2. System Requirements:
- ✅ **Moode Audio Compatibility:** Must work with Moode's display system
- ✅ **Update-Safe:** Must survive Moode updates
- ✅ **Future-Proof:** Should work with kernel/firmware updates
- ✅ **Maintainable:** Clean configuration, well documented
- ✅ **No Workarounds:** Proper solution, not hacks

### 3. Application Requirements:
- ✅ **Chromium:** Should work with Moode UI
- ✅ **Peppy Meter:** Should work (if used)
- ✅ **Touchscreen Apps:** Should work with correct coordinates
- ✅ **Other Apps:** Should work without special configuration

### 4. Configuration Requirements:
- ✅ **config.txt:** Clean, standard parameters
- ✅ **cmdline.txt:** No video parameter workarounds
- ✅ **xinitrc:** Standard Moode rotation logic (no hacks)
- ✅ **Moode Settings:** Should respect Moode display settings

---

## CONDITIONS TO CHECK BEFORE STARTING

### 1. Current System State:
- [ ] What is the current kernel version?
- [ ] What is the current firmware version?
- [ ] What is the current Moode Audio version?
- [ ] What is the actual HDMI port name? (HDMI-A-2 or HDMI-1?)
- [ ] What does `xrandr` currently show?
- [ ] What does `fbset` currently show?
- [ ] What does `/sys/class/drm/` show?

### 2. Moode Audio Integration:
- [ ] How does Moode handle display configuration?
- [ ] Where does Moode store display settings?
- [ ] Does Moode preserve config.txt across updates?
- [ ] How does Moode's xinitrc work?
- [ ] What display settings are available in Moode UI?

### 3. HDMI Configuration:
- [ ] What HDMI parameters work on Pi 5?
- [ ] Can we set 1280x400 directly without rotation?
- [ ] What KMS overlays are needed for Pi 5?
- [ ] Are there Pi 5 specific HDMI requirements?

### 4. Touchscreen:
- [ ] Is touchscreen connected via USB or I2C?
- [ ] What touchscreen driver is needed?
- [ ] How to configure touchscreen coordinates?

---

## GOALS

### Primary Goal:
**Create a stable, future-proof HDMI display solution for Pi 5 that:**
1. Starts directly in Landscape (1280x400)
2. Works with Moode Audio properly
3. Supports touchscreen correctly
4. Survives system updates
5. Uses clean, standard configuration

### Success Criteria:
- ✅ Display starts in Landscape (1280x400) without rotation
- ✅ Framebuffer reports correct resolution
- ✅ Chromium works with standard Moode configuration
- ✅ Touchscreen coordinates are correct
- ✅ Peppy Meter works (if used)
- ✅ No workarounds needed
- ✅ Configuration survives Moode updates

---

## NEXT STEPS

1. **Check Current System State** (on Pi 5)
   - Kernel version
   - Firmware version
   - Display status
   - Current configuration

2. **Research Pi 5 HDMI Requirements**
   - Official Pi 5 HDMI documentation
   - Moode Audio Pi 5 support
   - KMS configuration for Pi 5

3. **Develop Clean Solution**
   - Remove workarounds
   - Configure proper Landscape mode
   - Test touchscreen
   - Document configuration

4. **Test and Validate**
   - Verify all requirements met
   - Test update survival
   - Document final solution

---

**Status:** Requirements documented. Ready to check conditions and start implementation.

