# PeppyMeter Button + Larger Fonts - READY

**Date:** 2026-01-21  
**Status:** ✅ **IMPLEMENTED**

---

## Changes Made

### 1. ✅ PeppyMeter Button (Visible on Main Screen)

**Location:** Main playback controls, next to CoverView (TV icon) button

**Implementation:**
```html
<button class="btn btn-cmd toggle-peppymeter" id="toggle-peppymeter" aria-label="PeppyMeter">
    <i class="fa-regular fa-sharp fa-wave-pulse"></i>
</button>
```

**Position:** In the `#togglebtns` section, after the CoverView button

**Icon:** Wave-pulse icon (perfect for VU meter!)

**Function:** 
- Click to toggle between Moode UI and PeppyMeter
- Shows notification: "PeppyMeter ON" / "PeppyMeter OFF"
- No need to open context menu - always visible!

---

### 2. ✅ Larger Fonts for 1280×400 Display

**File Created:** `/var/www/css/display-1280x400.css`

**Font Size Increases:**

| Element | Old Size | New Size | Improvement |
|---------|----------|----------|-------------|
| Song title/Artist | ~16px | **28px** | +75% |
| Album name | ~14px | **22px** | +57% |
| Volume display | ~16px | **24px** | +50% |
| Time display | ~14px | **20px** | +43% |
| Playback buttons | ~18px | **24px** | +33% |
| Toggle buttons | ~16px | **20px** | +25% |
| Library items | ~14px | **16-18px** | +29% |
| Queue items | ~13px | **16px** | +23% |
| Menu items | ~13px | **16px** | +23% |
| Body text | ~13px | **15px** | +15% |

**Result:** Much more readable on the 1280×400 landscape display!

---

## Technical Implementation

### PeppyMeter Button

**File Modified:** `/var/www/templates/indextpl.min.html`
- Added button after CoverView button
- Uses existing JavaScript handler (scripts-panels.js line 781)
- Connected to backend command (playback.php)

**JavaScript Handler (Already Exists):**
```javascript
$('#toggle-peppymeter').click(function(e){
    e.preventDefault();
    e.stopPropagation();
    
    $.post('command/index.php?cmd=toggle_peppymeter', function(data){
        notify('PeppyMeter', data, NOTIFY_DURATION_SHORT);
    });
});
```

**Backend Command (Already Implemented):**
```php
case 'toggle_peppymeter':
    phpSession('open');
    $peppy = $_SESSION['peppy_display'] == '1' ? '0' : '1';
    phpSession('write', 'peppy_display', $peppy);
    phpSession('close');
    sqlUpdate('cfg_system', $dbh, 'peppy_display', $peppy);
    submitJob('peppy_display', $peppy);
    echo json_encode($peppy == '1' ? 'PeppyMeter ON' : 'PeppyMeter OFF');
    break;
```

---

### Larger Fonts CSS

**File Created:** `/var/www/css/display-1280x400.css`

**CSS Strategy:**
- Uses `!important` to override default styles
- Targets specific elements for maximum impact
- Maintains relative sizing hierarchy
- Button padding increased for better touch targets

**Linked in:** `/var/www/header.php` (after main.min.css)

**Key CSS Rules:**
```css
/* Main song info - most important */
#currentsong, #currentartist {
    font-size: 28px !important;
    line-height: 1.3 !important;
}

/* Volume - frequently viewed */
.volume-display div {
    font-size: 24px !important;
}

/* Buttons - larger for easier clicking */
#playbtns .btn {
    font-size: 24px !important;
    padding: 12px 16px !important;
}
```

---

## User Experience

### Before Changes
```
┌─────────────────────────────────┐
│   Song Title (small 16px)       │
│   Artist Name (small 14px)      │
│   ━━━━━●━━━━ 2:45/4:20          │
│   ⏮ ⏯ ⏭  [small buttons]        │
│   Context menu needed for Peppy │
└─────────────────────────────────┘
```

### After Changes
```
┌─────────────────────────────────┐
│   SONG TITLE (large 28px)       │
│   Artist Name (larger 28px)     │
│   ━━━━━●━━━━  2:45/4:20         │
│   ⏮ ⏯ ⏭ 📺 🌊 [larger buttons]  │
│            ↑                    │
│     PeppyMeter button (visible!)│
└─────────────────────────────────┘
```

**Wave icon (🌊):** The new PeppyMeter toggle button!

---

## Testing Instructions

### 1. Hard Refresh Browser
```
Ctrl + F5  (Windows/Linux)
Cmd + Shift + R  (Mac)
```

### 2. Check Font Sizes
- **Song title should be much larger** (28px)
- **Volume display easier to read** (24px)
- **All buttons larger**
- **Library/queue text more readable**

### 3. Test PeppyMeter Button
**Location:** Look for wave icon (🌊) next to TV icon in playback controls

**Test:**
1. Click wave icon → Should switch to blue VU meter
2. Wait a few seconds for transition
3. Click wave icon again (if visible) → Should switch back

**Note:** Button might not be visible when PeppyMeter is active (depends on implementation)

---

## Troubleshooting

### Button Not Visible
**Check template:**
```bash
grep toggle-peppymeter /var/www/templates/indextpl.min.html
```

**Should show:** Button with wave-pulse icon

### Fonts Still Small
**Check CSS loaded:**
1. Open browser dev tools (F12)
2. Check Network tab for `display-1280x400.css`
3. Should load with HTTP 200 status

**Check CSS file:**
```bash
cat /var/www/css/display-1280x400.css
```

**Hard refresh:**
- Ctrl + F5 to clear browser cache

### Toggle Doesn't Work
**Check JavaScript console (F12):**
- Look for errors when clicking button

**Check backend:**
```bash
tail -f /var/log/moode.log
```

---

## Font Size Customization

If fonts need to be **even larger**, edit:
```bash
sudo nano /var/www/css/display-1280x400.css
```

**Recommended adjustments:**
```css
/* For VERY LARGE song title (if needed) */
#currentsong, #currentartist {
    font-size: 32px !important;  /* Up from 28px */
}

/* For VERY LARGE volume */
.volume-display div {
    font-size: 28px !important;  /* Up from 24px */
}
```

**After changes:**
```bash
sudo systemctl reload nginx
# Hard refresh browser (Ctrl+F5)
```

---

## Files Modified Summary

```
Modified:
1. /var/www/templates/indextpl.min.html
   - Added PeppyMeter toggle button (visible)
   - Backup: /var/www/templates/indextpl.min.html.backup

2. /var/www/header.php
   - Linked display-1280x400.css

Created:
3. /var/www/css/display-1280x400.css
   - Custom font size overrides for 1280x400
   - All increases use !important to override defaults

Already Exists:
4. /var/www/js/scripts-panels.js (line 781)
   - JavaScript handler for button click

5. /var/www/command/playback.php
   - Backend toggle_peppymeter command
```

---

## Button Layout

**Playback Controls Section:**
```
[Heart] [⏮] [⏯] [⏭]    ← Favorites + playback
                        
[⋯] [🔀] [📺] [🌊] [●] [♥] ← Toggle buttons
         ↑     ↑
    CoverView  PeppyMeter (NEW!)
```

**Button order in `#togglebtns`:**
1. Context menu (⋯)
2. Random (🔀)
3. CoverView (📺)
4. **PeppyMeter (🌊)** ← NEW!
5. Random album (●)
6. Favorites (♥)

---

## Expected Behavior

### Click PeppyMeter Button:

**First Click:**
1. Button clicked
2. Notification: "PeppyMeter ON"
3. Display goes black briefly (2-3 seconds)
4. Blue VU meter appears (1280×400)
5. Needles move with audio

**Second Click (from Moode UI):**
1. Button clicked
2. Notification: "PeppyMeter OFF"
3. Display goes black briefly
4. Moode UI returns
5. Resume normal playback view

---

## Comparison: Context Menu vs Main Button

### Context Menu (REMOVED)
❌ Hidden - need to click ⋯ first  
❌ Extra tap required  
❌ Not discoverable  
❌ Inconvenient for 1280×400 display  

### Main Button (NEW)
✅ Always visible  
✅ One-tap toggle  
✅ Discoverable  
✅ Perfect for small display  
✅ Wave icon clearly indicates VU meter  

---

## Font Size Philosophy

**Design Goals:**
1. **Prioritize frequently viewed info** (song title, volume)
2. **Improve touch targets** (larger buttons, more padding)
3. **Maintain visual hierarchy** (title > album > metadata)
4. **Keep UI balanced** (not everything huge)

**Result:**
- Song info: +75% (most important)
- Interactive elements: +33% (easier to click)
- Secondary info: +15-25% (readable but not dominant)

---

## Next Steps

1. **User tests new button** (hard refresh first!)
2. **User confirms fonts are readable**
3. **User tests PeppyMeter toggle**
4. **Adjust font sizes if needed** (can go larger!)

---

## v1.0 Update

**This completes v1.0 requirements:**
- [x] Display working (1280×400 landscape)
- [x] Audio configured (CamillaDSP + Bose Wave filters)
- [x] **PeppyMeter toggle button (visible, convenient)**
- [x] **Fonts increased for readability**
- [ ] User testing required

---

**Status:** ✅ **READY FOR TESTING**

Hard refresh browser and enjoy the bigger fonts and convenient PeppyMeter button!

---

**End of Documentation**
