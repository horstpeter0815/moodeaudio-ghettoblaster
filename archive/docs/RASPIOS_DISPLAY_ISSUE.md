# RaspiOS Full Display Issue - 1280x400 Not Working

## Problem
- Display shows **400x1280** (Portrait) instead of **1280x400** (Landscape)
- `hdmi_cvt=1280 400 60 6 0 0 0` is set in `config.txt` and recognized by firmware
- Firmware shows: `hdmi_cvt:0=1280 400 60 6 0 0 0`
- But display still reports 400x1280 via EDID

## Current Configuration (RaspiOS Full - 192.168.178.143)

### config.txt [pi5] section:
```
[pi5]
hdmi_cvt=1280 400 60 6 0 0 0
display_rotate=0
hdmi_force_hotplug=1
hdmi_edid_file=0
hdmi_ignore_edid_startup=0xa5000080
hdmi_ignore_edid=0xa5000080
```

### Status:
- ✅ Firmware recognizes hdmi_cvt
- ✅ EDID ignore is set
- ❌ Display still shows 400x1280
- ✅ Touchscreen detected and working
- ✅ DPI: 121x120 (improved from 97x96)

## Root Cause Analysis

The display hardware (Waveshare 7.9" HDMI LCD) is reporting its native resolution as 400x1280 via EDID. Even though:
1. `hdmi_cvt` is set correctly
2. EDID is being ignored
3. Firmware recognizes the setting

The display driver/KMS is still using the EDID-reported resolution.

## Possible Solutions

1. **Hardware-level EDID override** - May need to physically modify EDID or use EDID file
2. **KMS driver configuration** - May need to configure DRM/KMS directly
3. **Display firmware update** - Waveshare display firmware might need update
4. **Alternative: Use xrandr rotation** - But this is a WORKAROUND (not desired)

## Next Steps

1. Check if Waveshare provides EDID override file
2. Try creating custom EDID file with 1280x400
3. Check KMS/DRM configuration
4. Contact Waveshare support for Pi 5 compatibility

## Note

The user wants NO WORKAROUNDS. The display must start in 1280x400 Landscape mode directly from boot, configured in `config.txt` only.

