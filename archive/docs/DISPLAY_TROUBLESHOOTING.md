# Display Troubleshooting: White Screen with Black Lines

## Problem
Display shows completely white screen with a few black lines - indicates incorrect HDMI timings.

## Possible Causes
1. **Pixel clock too high/low** - causes sync issues
2. **Wrong timing values** - H/V sync, front/back porch incorrect
3. **Timing calculation error** - values don't match display capabilities

## Solutions Being Tested

### Option 1: Use hdmi_cvt instead of hdmi_timings
- `hdmi_cvt=1280 400 60 6 0 0 0`
- More reliable, firmware calculates timings automatically

### Option 2: Remove custom timings, use EDID + rotation
- Use 400x1280 from EDID (known to work)
- Rotate via xrandr to get 1280x400
- This is a workaround but should work

### Option 3: Corrected hdmi_timings with lower pixel clock
- Reduce pixel clock from 35860 to 30000 kHz
- More conservative timing values
- May be more compatible with display

## Current Test
Testing Option 3: Conservative timings with 30 MHz pixel clock

## Next Steps
1. Test each option
2. Find working combination
3. Document working values

