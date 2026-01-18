# WebUI 400x1280 (Portrait) Configuration

**Date:** 2025-12-25  
**Change:** WebUI window size changed from 1280x400 to 400x1280 (portrait)

---

## Configuration Applied

### File Modified: `/home/andre/.xinitrc`

**Changed:**
```bash
# Before:
--window-size="$SCREEN_RES" \

# After:
--window-size="400,1280" \
```

### Effect:
- Chromium WebUI will now start with window size **400x1280** (portrait)
- This is independent of the actual display resolution
- Chromium will display the WebUI in portrait orientation

---

## Display Considerations

### Physical Display:
- **Hardware:** 1280x400 (landscape)
- **Framebuffer:** May be 1280x400 or 400x1280 depending on rotation

### WebUI Window:
- **Size:** 400x1280 (portrait)
- **Orientation:** Portrait (taller than wide)

### Options:
1. **Display stays 1280x400, WebUI window is 400x1280:**
   - WebUI will be displayed in portrait mode
   - May need to scroll or rotate display

2. **Display rotated to 400x1280, WebUI window is 400x1280:**
   - Display and WebUI match
   - Requires display rotation at boot or X11 level

---

## Verification

After restart, check:
1. Chromium window size: Should be 400x1280
2. Display orientation: May need rotation to match
3. WebUI display: Should be in portrait mode

---

**Status:** ✅ Configuration applied - WebUI set to 400x1280










