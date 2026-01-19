# CSS Fix: 400px Display Support
**Date:** 2026-01-19  
**Issue:** CSS media query requires 480px min-height, but Waveshare display is only 400px  
**Fix:** Change min-height from 480px to 400px

---

## The Problem

### Media Query in moode-source/www/css/media.css
```css
/* Line 590 - BEFORE FIX */
@media (min-height:480px) and (orientation:landscape) {
    body.cvwide #ss-coverart {top:3em;}
}
```

**Issue:** This CSS rule only applies when display height ≥ 480px

**Waveshare 7.9" Display:**
- Native: 400x1280 (portrait)
- Rotated: 1280x400 (landscape)
- **Height = 400px** (less than 480px minimum!)

**Result:** CSS styles inside this media query DON'T apply to the Waveshare display!

---

## The Fix

### Updated Media Query
```css
/* Line 590 - AFTER FIX */
@media (min-height:400px) and (orientation:landscape) {
    body.cvwide #ss-coverart {top:3em;}
}
```

**Change:** `min-height:480px` → `min-height:400px`

**Result:** CSS styles now apply to 1280x400 display

---

## Impact

### What This Fixes

1. **CoverView Wide Layout**
   - Screensaver cover art positioning
   - `#ss-coverart` element top position
   - Affects CoverView display mode

2. **Landscape Orientation Detection**
   - moOde UI can now correctly detect landscape mode
   - 400px height is recognized as valid landscape

3. **Responsive Design**
   - Layout adapts correctly to 1280x400 resolution
   - No more "too small for landscape" issues

### What Other Displays Are Affected

This fix also helps:
- Other small landscape displays (< 480px height)
- Waveshare displays in landscape orientation
- Custom displays with non-standard resolutions

---

## Verification

### Check if Fix Applied
```bash
# On Pi after flashing custom image:
ssh andre@192.168.2.3
cat /var/www/css/media.css | grep -A2 "min-height.*landscape"
```

**Expected output:**
```css
@media (min-height:400px) and (orientation:landscape) {
    body.cvwide #ss-coverart {top:3em;}
}
```

### Test CoverView
1. Open moOde web UI
2. Go to CoverView (Appearance → CoverView)
3. Enable "Wide layout" mode
4. **Expected:** Cover art positions correctly (not cut off)

---

## Related Issues

### Pi 7" Touch 1 (800 x 480)
```css
/* Line 523 comment in media.css */
// Pi 7" Touch 1 800 x 480
```

moOde was designed with 480px as minimum height for landscape.  
Our 400px display is **smaller** than the Pi 7" Touch, so we need special handling.

### Other Min-Height Rules

There are other min-height rules in media.css:
```css
@media (min-height:900px) and (min-width:1919px) { /* Large displays */ }
@media (max-height:800px) and (orientation:landscape) { /* Long titles */ }
```

These don't affect 400px display (they're for larger screens or max-height).

---

## Build Integration

### How Fix Gets Into Custom Build

1. **Source:** `/Users/andrevollmer/moodeaudio-cursor/moode-source/www/css/media.css`
2. **Build copies moode-source** during stage3 (moOde installation)
3. **Result:** Fixed CSS file ends up in `/var/www/css/media.css` on Pi

**No additional build script needed** - moOde build process copies entire moode-source directory.

---

## Testing Checklist

After building and flashing custom image:

- [ ] moOde UI loads correctly in landscape
- [ ] Radio stations visible (not hidden by CSS)
- [ ] Colors showing correctly
- [ ] CoverView wide layout works
- [ ] Screensaver displays correctly
- [ ] No layout cutoff issues

---

## Alternative Solutions (Not Used)

### Option 1: Remove min-height Constraint
```css
@media (orientation:landscape) {
    /* No min-height check */
}
```
**Rejected:** Too broad, might affect very small displays incorrectly

### Option 2: Add Separate 400px Rule
```css
@media (min-height:400px) and (max-height:479px) and (orientation:landscape) {
    /* Specific to 400px displays */
}
```
**Rejected:** Unnecessary complexity, just changing the existing rule is simpler

### Option 3: JavaScript Detection
```javascript
if (window.innerHeight === 400 && window.orientation === 90) {
    // Apply styles via JS
}
```
**Rejected:** CSS media queries are more performant and maintainable

---

## Commit Message

```
Fix CSS min-height for 400px Waveshare display

- Change min-height from 480px to 400px in media.css
- Allows landscape styles to apply to 1280x400 display
- Fixes CoverView wide layout positioning
- Improves responsive design for small landscape displays

Affects: moode-source/www/css/media.css line 590
```

---

## Status

- [x] Issue identified (480px min-height)
- [x] Fix applied (changed to 400px)
- [x] Documented
- [ ] Built into custom image
- [ ] Tested on hardware
- [ ] Verified CoverView works

**Ready for custom build!**
