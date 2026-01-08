# Final Working Solution: 1280x400 on Moode Audio

## Problem Solved ✅
Display now shows 1280x400 landscape mode on both RaspiOS Full and Moode Audio.

## Key Discovery
**Moode Audio uses `/boot/firmware/config.txt`, NOT `/boot/config.txt`!**

## Working Configuration

### /boot/firmware/config.txt
```ini
disable_fw_kms_setup=1

[pi5]
hdmi_timings=1280 32 48 80 400 10 3 2 60 35860 0 0 0 0 0
hdmi_group=2
hdmi_mode=87
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
display_rotate=0
```

### /boot/firmware/cmdline.txt
```
... video=HDMI-A-2:1280x400M@60
```

## What Actually Works
1. **`hdmi_timings`** (not `hdmi_cvt`) - works with `disable_fw_kms_setup=1`
2. **`video=` parameter in cmdline.txt** - helps KMS recognize the mode
3. **Correct config file** - `/boot/firmware/config.txt` on Moode Audio

## Auto-Start Web UI

### ~/.xinitrc
```bash
#!/bin/bash
sleep 2
export DISPLAY=:0

# Set 1280x400 mode
if xrandr 2>/dev/null | grep -q "1280x400"; then
    xrandr --output HDMI-2 --mode 1280x400 2>/dev/null
fi

# Touchscreen
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
if [ ! -z "$TOUCH_DEVICE" ]; then
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
fi

# Start Chromium
chromium --app="http://localhost/" --kiosk --window-size=1280,400
```

## Verification
```bash
# Check available modes
cat /sys/class/drm/card1-HDMI-A-2/modes
# Should show: 400x1280 1280x720 1280x400

# Check current resolution
DISPLAY=:0 xrandr | grep "current"
# Should show: current 1280 x 400
```

## Status
✅ 1280x400 mode available in KMS
✅ Mode can be set via xrandr
✅ Web UI configured to start automatically
⏳ Testing touchscreen calibration

