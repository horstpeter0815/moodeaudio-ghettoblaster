# Fixing Image Size Issue

## Problem
Image is smaller than screen - black bars on left and right sides.

## Possible Causes
1. **Overscan enabled** - image is being scaled down
2. **Wrong scaling** - xrandr transform/scale reducing size
3. **Display's own scaling** - hardware scaling on the display
4. **Rotation causing size reduction**

## Solutions Applied

### 1. Disable Overscan
```ini
disable_overscan=1
```
Added to `/boot/firmware/config.txt`

### 2. Remove Scaling/Transform
In xinitrc:
```bash
xrandr --output HDMI-2 --transform none
xrandr --output HDMI-2 --scale 1x1
```

### 3. Set Mode Correctly
```bash
xrandr --output HDMI-2 --mode 400x1280
xrandr --output HDMI-2 --rotate left
```

## Status
✅ Overscan disabled
✅ Scaling removed in xinitrc
⏳ Testing if image now fills screen

## Next Steps
If still not filling:
1. Check display's hardware settings
2. Try different rotation method
3. Adjust Chromium window size
4. Use custom mode with exact timings

