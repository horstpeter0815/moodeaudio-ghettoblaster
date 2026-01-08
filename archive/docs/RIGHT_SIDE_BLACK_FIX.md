# Fixing Right Side Black Area

## Problem
- Left side: Image is correct, aligned to edge ✅
- Right side: About 1/5 of screen is black/unused ❌
- Image is not cut off, just not using full width

## Possible Causes
1. **Rotated mode size mismatch** - 400x1280 rotated left might not give exactly 1280x400
2. **Chromium window size** - Window might be smaller than display
3. **Viewport issue** - Chromium's viewport not matching display
4. **Framebuffer size** - Framebuffer might be wrong size

## Solutions Being Tried

### 1. Explicit Window Size and Position
```bash
chromium --window-size=1280,400 --window-position=0,0
```

### 2. Framebuffer Settings
```ini
framebuffer_width=1280
framebuffer_height=400
```

### 3. Check Actual Mode Size
- Verify what size the rotated mode actually reports
- May need to use right rotation instead of left
- Or create custom mode

### 4. Force Position
```bash
xrandr --output HDMI-2 --pos 0x0
```

## Status
⏳ Testing different approaches to fill right side

