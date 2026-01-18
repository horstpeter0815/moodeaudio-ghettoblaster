# Touch Calibration - Working Configuration

**Date:** 2026-01-18  
**Status:** ✅ WORKING CONFIGURATION RESTORED

## Working Touch Calibration

**File:** `/etc/X11/xorg.conf.d/99-calibration.conf`

```ini
Section "InputClass"
    Identifier "calibration"
    MatchProduct "FT6236|ft6236"
    Option "Calibration" "0 1280 0 400"
    Option "SwapAxes" "0"
EndSection
```

## Key Settings

- **Calibration:** `0 1280 0 400` - Matches 1280x400 landscape display
- **SwapAxes:** `0` - No axis swapping (axes are correct)
- **No inversions** - X and Y are not inverted
- **No complex transformations** - Simple calibration only

## Display Configuration

- **Display:** 1280x400 landscape (rotated 90° left from 400x1280)
- **Rotation:** `xrandr --output HDMI-2 --mode 400x1280 --rotate left`

## Important Notes

⚠️ **DO NOT ADD:**
- TransformationMatrix (causes misalignment)
- InvertX or InvertY (causes wrong coordinates)
- SwapAxes=1 (causes dismiss button issues)

✅ **KEEP SIMPLE:**
- Just basic Calibration option
- SwapAxes=0
- MatchProduct for FT6236

## Restore Command

If touch breaks, restore with:
```bash
sudo tee /etc/X11/xorg.conf.d/99-calibration.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "calibration"
    MatchProduct "FT6236|ft6236"
    Option "Calibration" "0 1280 0 400"
    Option "SwapAxes" "0"
EndSection
EOF
sudo systemctl restart localdisplay
```
