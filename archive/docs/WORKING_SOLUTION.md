# Working Solution: 1280x400 Landscape on Pi 5

## Problem Solved
Display was showing 400x1280 (Portrait) instead of 1280x400 (Landscape) on Raspberry Pi 5.

## Root Cause
- Pi 5 uses `card1` for HDMI (not `card0`)
- With `disable_fw_kms_setup=1`, firmware's `hdmi_cvt` is ignored by KMS
- KMS reads EDID directly from display, which reports 400x1280 as preferred
- Solution: Override EDID with custom file that reports 1280x400

## Solution: Custom EDID File

### Step 1: Create Modified EDID
The EDID file must be created with proper timing calculations for 1280x400@60Hz.

**Timing Parameters (CVT reduced blanking):**
- H total: 1440 (1280 active + 48 front + 32 sync + 80 back)
- V total: 415 (400 active + 3 front + 10 sync + 2 back)
- Pixel clock: 35.856 MHz (35856 kHz)

### Step 2: Modify EDID DTD
The first Detailed Timing Descriptor (DTD) at offset 0x36 must be modified to report 1280x400.

### Step 3: Apply EDID File
1. Save modified EDID as `/boot/firmware/edid-1280x400.bin`
2. Add to `config.txt`:
   ```
   [pi5]
   hdmi_edid_file=edid-1280x400.bin
   hdmi_ignore_edid=0xa5000080
   hdmi_force_hotplug=1
   display_rotate=0
   ```

### Step 4: Verify
After reboot, check:
- `cat /sys/class/drm/card1-HDMI-A-2/modes` should include `1280x400`
- `DISPLAY=:0 xrandr` should show 1280x400 as available
- Set mode: `DISPLAY=:0 xrandr --output HDMI-A-2 --mode 1280x400`

## Status
✅ Mode `1280x400` is now available in KMS
🔄 Testing activation and persistence

## Next Steps
1. Ensure mode activates automatically on boot
2. Apply same solution to Moode Audio
3. Test touchscreen calibration with correct orientation

