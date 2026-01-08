# Comprehensive Learning: Pi 5 Display Configuration

## Core Problem
Raspberry Pi 5 with Waveshare 7.9" HDMI LCD (1280x400 native) shows 400x1280 (Portrait) instead of 1280x400 (Landscape).

## Root Cause Analysis

### Key Discoveries
1. **Pi 5 uses `card1` for HDMI** (not `card0` like older Pis)
2. **`disable_fw_kms_setup=1` prevents firmware from controlling KMS**
3. **KMS reads EDID directly from display** - EDID reports 400x1280 as preferred
4. **Firmware `hdmi_cvt` is recognized** but not applied when `disable_fw_kms_setup=1`
5. **EDID file override (`hdmi_edid_file`) doesn't work** with `disable_fw_kms_setup=1`

### Technical Details
- **KMS Driver:** `vc4-drm` on `card1`
- **EDID Size:** 256 bytes
- **Current EDID Preferred:** 400x1280@59.5Hz
- **Available Modes (from EDID):** `400x1280`, `1280x720`
- **Mode `1280x400` appears** after EDID modification attempts, but cannot be activated

## Methods Tested

### Method 1-6: Various config.txt approaches
- ❌ `hdmi_timings` (firmware format)
- ❌ `framebuffer_width/height` + `hdmi_cvt`
- ❌ `hdmi_group=2` + `hdmi_mode=87` + `hdmi_cvt`
- ❌ Strongest EDID ignore flags
- ❌ `hdmi_cvt` in `[all]` section
- ❌ `video=` parameter in `cmdline.txt`

### Method 7: Custom EDID File
- Created modified EDID with 1280x400 as DTD 1
- **Problem:** `hdmi_edid_file` not loaded by firmware
- **Finding:** `vcgencmd get_config hdmi_edid_filename` shows empty
- **Conclusion:** `hdmi_edid_file` doesn't work with `disable_fw_kms_setup=1`

### Method 8: Remove disable_fw_kms_setup
- Removed `disable_fw_kms_setup=1`
- Combined with `hdmi_edid_file` and `hdmi_cvt`
- **Status:** Testing...

### Method 9: hdmi_timings (Web Research)
- Using format: `hdmi_timings=1280 32 48 80 400 10 3 2 60 35860 0 0 0 0 0`
- Combined with `hdmi_group=2` and `hdmi_mode=87`
- **Status:** Testing...

## Current Understanding

### Why Methods Fail
1. **With `disable_fw_kms_setup=1`:**
   - Firmware settings (`hdmi_cvt`, `hdmi_timings`) are ignored by KMS
   - KMS reads EDID directly from hardware
   - `hdmi_edid_file` is not processed

2. **Without `disable_fw_kms_setup=1`:**
   - Firmware should control KMS
   - But EDID from display still overrides firmware settings
   - Need to test if firmware can override EDID

### Possible Solutions
1. **Remove `disable_fw_kms_setup`** and use firmware KMS control
2. **Modify EDID at hardware level** (if possible)
3. **Use X11/Wayland to force mode** after boot
4. **Create proper EDID file** that firmware can load (if `disable_fw_kms_setup=0`)

## Next Steps
1. ✅ Test Method 8 (without `disable_fw_kms_setup`)
2. ✅ Test Method 9 (`hdmi_timings`)
3. ⏳ If both fail, try X11-based solution
4. ⏳ Research Pi 5 specific KMS configuration

## Lessons Learned
- Pi 5 display stack is different from Pi 4
- `disable_fw_kms_setup=1` fundamentally changes how display works
- EDID is the source of truth for KMS
- Need to either override EDID or work around it

