# Pi 5 HDMI Research - Clean Landscape Solution

**Date:** 2025-01-27  
**Goal:** Find clean solution for 1280x400 Landscape mode without workarounds

---

## CURRENT PROBLEM

### Workarounds in Use:
1. **Portrait Start:** `video=HDMI-A-2:400x1280M@60,rotate=90` in cmdline.txt
2. **xrandr Rotation:** `xrandr --output HDMI-2 --rotate left` in xinitrc
3. **Hardcoded Window Size:** `--window-size="1280,400"` in Chromium

### Issues:
- Display must start Portrait then rotate
- Touchscreen coordinates wrong
- Peppy Meter doesn't work
- Not update-safe
- Not a clean solution

---

## RESEARCH FINDINGS

### Pi 5 HDMI Configuration

#### Key Parameters:
- **KMS Overlay:** `dtoverlay=vc4-kms-v3d-pi5` (Pi 5 specific)
- **HDMI Group/Mode:** `hdmi_group=2`, `hdmi_mode=87` (custom mode)
- **HDMI CVT:** `hdmi_cvt 1280 400 60 6 0 0 0` (custom resolution)

#### Current Config Analysis:
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
```

**Observation:** The `hdmi_cvt` specifies 1280x400, but the system still starts in Portrait mode.

---

## POSSIBLE SOLUTIONS

### Solution 1: Remove video parameter, use only config.txt

**Theory:** The `video=` parameter in cmdline.txt might be forcing Portrait mode.

**Test:**
1. Remove `video=HDMI-A-2:400x1280M@60,rotate=90` from cmdline.txt
2. Keep `hdmi_cvt 1280 400 60 6 0 0 0` in config.txt
3. Let KMS handle the resolution directly

**Expected:** Display should start in Landscape (1280x400) directly.

---

### Solution 2: Use display_rotate parameter

**Theory:** `display_rotate` in config.txt might work better than cmdline video parameter.

**Test:**
```ini
hdmi_cvt 1280 400 60 6 0 0 0
display_rotate=0  # No rotation, direct Landscape
```

**Expected:** Direct Landscape mode without rotation.

---

### Solution 3: KMS mode setting

**Theory:** With True KMS (vc4-kms-v3d-pi5), we can set mode directly via KMS.

**Test:**
- Remove all hdmi_* parameters
- Let KMS detect and set mode
- Use xrandr to set mode if needed

**Expected:** KMS should handle custom resolution properly.

---

### Solution 4: Framebuffer direct configuration

**Theory:** Configure framebuffer directly to 1280x400.

**Test:**
```bash
fbset -fb /dev/fb0 -g 1280 400 1280 400 32
```

**Expected:** Framebuffer reports correct resolution from start.

---

## MOODE AUDIO INTEGRATION

### Current Moode Settings:
- `hdmi_scn_orient = 'landscape'`
- `dsi_scn_type = 'none'`

### Moode xinitrc Behavior:
- Moode's xinitrc reads `hdmi_scn_orient` from database
- If `landscape`, should not rotate
- But current workaround forces rotation anyway

### Clean Integration:
1. Set Moode to `landscape`
2. Remove forced rotation from xinitrc
3. Let Moode handle rotation based on settings
4. Ensure display starts in correct orientation

---

## TESTING PLAN

### Step 1: Remove cmdline video parameter
- Remove `video=HDMI-A-2:400x1280M@60,rotate=90`
- Keep config.txt settings
- Reboot and test

### Step 2: Test direct Landscape
- Check if display starts in Landscape
- Check framebuffer resolution
- Check xrandr output

### Step 3: Adjust if needed
- If still Portrait, try `display_rotate=0`
- If still issues, try KMS mode setting
- Document what works

### Step 4: Clean xinitrc
- Remove forced rotation
- Let Moode handle it
- Test Chromium window size

### Step 5: Test touchscreen
- Verify coordinates
- Test Peppy Meter
- Test other apps

---

## KEY QUESTIONS TO ANSWER

1. **Why does display start in Portrait?**
   - Is it the video parameter?
   - Is it the hdmi_cvt parameter?
   - Is it a firmware limitation?

2. **Can we set 1280x400 directly?**
   - Does hdmi_cvt work correctly?
   - Does KMS support this resolution?
   - Is firmware the issue?

3. **What's the cleanest way?**
   - config.txt only?
   - KMS mode setting?
   - Framebuffer configuration?

---

## NEXT STEPS

1. **Research Pi 5 HDMI documentation**
   - Official Raspberry Pi docs
   - Forum discussions
   - Known issues

2. **Test configurations**
   - Remove workarounds one by one
   - Document results
   - Find what works

3. **Create clean solution**
   - Minimal config.txt
   - Clean cmdline.txt
   - Standard xinitrc
   - Working touchscreen

---

**Status:** Research in progress. Will test configurations and document findings.

