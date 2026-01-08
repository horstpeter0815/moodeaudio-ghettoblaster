# Fixing White Screen with Black Lines

## Problem
Display shows completely white screen with black lines - indicates HDMI timing sync issues.

## Root Cause
The `hdmi_timings` values (especially pixel clock) are incorrect for this display, causing sync failures.

## Solution: EDID Mode + Rotation (Workaround)

Since custom timings cause sync issues, use the display's native EDID mode (400x1280) which we know works, then rotate it via xrandr.

### Configuration

**config.txt:**
```ini
[pi5]
hdmi_force_hotplug=1
display_rotate=0
```

**xinitrc:**
```bash
# Set to EDID mode (400x1280) - this works
xrandr --output HDMI-2 --mode 400x1280
sleep 1

# Rotate to get 1280x400 landscape
xrandr --output HDMI-2 --rotate left

# Adjust touchscreen for rotation
# Matrix for left rotation: 0 -1 1 1 0 0 0 0 1
xinput set-prop <touchscreen_id> "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
```

## Why This Works
- EDID mode (400x1280) is tested and works
- Rotation via xrandr is reliable
- No custom timing calculations needed
- Display hardware handles the mode correctly

## Status
Testing this approach - should eliminate white screen issue.

