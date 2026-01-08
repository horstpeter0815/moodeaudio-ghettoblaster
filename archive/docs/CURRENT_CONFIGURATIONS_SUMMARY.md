# Current Configurations Summary - Pi 5

**Date:** 2025-01-27  
**Hardware:** Raspberry Pi 5 with BOTH HDMI and DSI displays

---

## HDMI CONFIGURATION (Currently Working with Workarounds)

### Location: `PI5_WORKING_CONFIG.txt`

**Key Settings:**
- `dtoverlay=vc4-kms-v3d-pi5,noaudio` (Pi 5 specific KMS)
- `dtoverlay=vc4-kms-v3d` (Base KMS)
- `hdmi_group=2`, `hdmi_mode=87`
- `hdmi_cvt 1280 400 60 6 0 0 0`
- `hdmi_force_hotplug=1`

**cmdline.txt:**
- `video=HDMI-A-2:400x1280M@60,rotate=90` (WORKAROUND: Portrait start)

**xinitrc:**
- `xrandr --output HDMI-2 --rotate left` (WORKAROUND: Rotation)
- `--window-size="1280,400"` (WORKAROUND: Hardcoded size)

**Issues:**
- Must start in Portrait (400x1280) then rotate
- Touchscreen coordinates wrong
- Peppy Meter doesn't work
- Not a clean solution

---

## DSI CONFIGURATION (From Previous Work)

### Status: Not Currently Active (Commented Out)

**From config.txt:**
```ini
#dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0
```

**Known Issues (from PROJECT_FINAL_SUMMARY.md):**
- CRTC not assigned (`possible_crtcs=0x0`)
- FKMS doesn't create CRTC for DSI
- Firmware doesn't report DSI
- Display stays disabled

**Previous Work:**
- FKMS Patch V4 developed (not compiled/tested)
- Driver patches applied
- Root cause identified

---

## GOAL: Clean HDMI Solution

**Requirements:**
1. Direct Landscape start (1280x400) - NO rotation
2. Clean config.txt - NO workarounds
3. Clean cmdline.txt - NO video parameter hacks
4. Standard xinitrc - NO forced rotation
5. Touchscreen working correctly
6. Update-safe configuration

---

## NEXT STEPS

1. Research direct 1280x400 Landscape mode
2. Find proper Pi 5 HDMI configuration
3. Remove all workarounds
4. Test touchscreen configuration
5. Document clean solution

---

**Status:** Configurations documented. Research in progress...

