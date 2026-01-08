# Stable HDMI Solution Plan - Pi 5

**Date:** 2025-01-27  
**Goal:** Clean, stable HDMI solution without workarounds

---

## OBJECTIVE

Create a clean HDMI configuration for Pi 5 that:
- ✅ Starts directly in Landscape (1280x400)
- ✅ No rotation workarounds
- ✅ Touchscreen works correctly
- ✅ Peppy Meter works
- ✅ Update-safe
- ✅ Future-proof

---

## CURRENT STATE ANALYSIS

### What Works:
- Display shows image
- Chromium displays Moode UI
- System is stable

### What Doesn't Work:
- Must start Portrait then rotate (workaround)
- Touchscreen coordinates wrong
- Peppy Meter broken
- Not a clean solution

### Current Workarounds:
1. `video=HDMI-A-2:400x1280M@60,rotate=90` in cmdline.txt
2. `xrandr --output HDMI-2 --rotate left` in xinitrc
3. `--window-size="1280,400"` hardcoded in Chromium

---

## SOLUTION APPROACH

### Phase 1: Remove cmdline video parameter

**Hypothesis:** The `video=` parameter is forcing Portrait mode.

**Action:**
1. Remove `video=HDMI-A-2:400x1280M@60,rotate=90` from cmdline.txt
2. Keep `hdmi_cvt 1280 400 60 6 0 0 0` in config.txt
3. Reboot and test

**Expected Result:** Display should start in Landscape if hdmi_cvt is working correctly.

---

### Phase 2: Clean config.txt

**Target Configuration:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
hdmi_force_hotplug=1
hdmi_drive=2
display_rotate=0
```

**Key Changes:**
- Remove DSI-related settings (not needed for HDMI)
- Keep only HDMI settings
- Add `display_rotate=0` to ensure no rotation

---

### Phase 3: Clean cmdline.txt

**Target Configuration:**
```
console=serial0,115200 console=tty1 root=PARTUUID=47dfe65d-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE
```

**Key Changes:**
- Remove `video=HDMI-A-2:400x1280M@60,rotate=90`
- Let config.txt handle display configuration

---

### Phase 4: Clean xinitrc

**Target Configuration:**
- Remove forced rotation: `DISPLAY=:0 xrandr --output HDMI-2 --rotate left`
- Let Moode handle rotation based on `hdmi_scn_orient` setting
- Use `$SCREEN_RES` for Chromium window size (not hardcoded)

**Moode Integration:**
- Set `hdmi_scn_orient = 'landscape'` in Moode
- Moode's xinitrc should handle rotation correctly
- No manual rotation needed

---

### Phase 5: Touchscreen Configuration

**If touchscreen is USB:**
- Configure via `xinput` or `libinput`
- Set coordinate transformation matrix
- Test with `xinput test` or `evtest`

**If touchscreen is I2C:**
- May need device tree overlay
- Configure via `xinput` or `libinput`
- Test coordinates

---

## TESTING PROCEDURE

### Test 1: Boot and Check Resolution
```bash
# After reboot, check:
xrandr
fbset -s
cat /sys/class/drm/card*/status
```

**Expected:**
- xrandr shows `HDMI-2 connected 1280x400+0+0` (no rotation)
- fbset shows `geometry 1280 400`
- Display shows full image in Landscape

### Test 2: Chromium Window
- Chromium should use correct window size
- No cut-off issues
- Full Moode UI visible

### Test 3: Touchscreen
- Coordinates match display
- Touch works correctly
- No offset issues

### Test 4: Peppy Meter
- Should work correctly
- No orientation issues
- Correct resolution

---

## ROLLBACK PLAN

If something doesn't work:

1. **Restore cmdline.txt:**
   - Add back `video=HDMI-A-2:400x1280M@60,rotate=90`

2. **Restore xinitrc:**
   - Add back `xrandr --output HDMI-2 --rotate left`

3. **Restore Chromium:**
   - Add back `--window-size="1280,400"`

**Keep backups of working configuration!**

---

## IMPLEMENTATION STEPS

### Step 1: Backup Current Config
```bash
cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
cp /home/andre/.xinitrc /home/andre/.xinitrc.backup
```

### Step 2: Modify config.txt
- Remove DSI settings
- Ensure `display_rotate=0`
- Keep HDMI settings

### Step 3: Modify cmdline.txt
- Remove `video=` parameter
- Keep other parameters

### Step 4: Modify xinitrc
- Remove forced rotation
- Let Moode handle it
- Use `$SCREEN_RES` for Chromium

### Step 5: Reboot and Test
- Reboot Pi 5
- Run diagnostic script
- Test display
- Test touchscreen
- Test Peppy Meter

### Step 6: Document Results
- What worked
- What didn't work
- What needs adjustment

---

## SUCCESS CRITERIA

✅ Display starts in Landscape (1280x400)  
✅ No rotation workarounds needed  
✅ Framebuffer reports correct resolution  
✅ Chromium works with standard config  
✅ Touchscreen coordinates correct  
✅ Peppy Meter works  
✅ Configuration is clean and maintainable  
✅ Survives Moode updates  

---

## NEXT ACTIONS

1. **When you return:**
   - Run diagnostic script on Pi 5
   - Review current state
   - Test Phase 1 (remove video parameter)

2. **If Phase 1 works:**
   - Continue with Phase 2-5
   - Test each phase
   - Document results

3. **If Phase 1 doesn't work:**
   - Investigate why
   - Try alternative approaches
   - Document findings

---

**Status:** Plan ready. Waiting for diagnostic results and testing.

