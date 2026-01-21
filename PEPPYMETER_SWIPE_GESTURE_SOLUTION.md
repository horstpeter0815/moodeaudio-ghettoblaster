# PeppyMeter Swipe Gesture Control - Complete Solution

**Date:** 2026-01-21  
**Status:** ✅ Ready to Install

---

## Problem

When PeppyMeter is active, it runs fullscreen and covers the moOde UI completely. There's no way to exit PeppyMeter by touching the display - you're stuck until you SSH in or reboot.

## Solution

Implement **swipe gesture detection** that allows you to exit PeppyMeter by swiping up or down on the touchscreen.

---

## How It Works

```
┌─────────────────────────────────────────────────┐
│                                                 │
│         PeppyMeter Running (Fullscreen)         │
│                                                 │
│         [Blue VU Meter with needles]            │
│                                                 │
│                     ↕                           │
│              SWIPE UP or DOWN                   │
│                     ↕                           │
│         → Switches to moOde UI ←                │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Technical Implementation:**

1. **Transparent Overlay Layer**
   - Pygame creates an invisible overlay on top of PeppyMeter
   - Touch events are captured by the overlay
   - PeppyMeter continues to display underneath

2. **Swipe Detection**
   - Touch down: Record starting position and time
   - Touch up: Calculate distance and duration
   - If vertical movement ≥ 100px and time ≤ 0.8s → SWIPE detected

3. **Toggle Action**
   - Update database: `peppy_display = 0`
   - Restart `localdisplay` service
   - .xinitrc reads database and launches Chromium (moOde UI)

---

## Files Created

### 1. Swipe Detection Wrapper
**File:** `/usr/local/bin/peppymeter-swipe-wrapper.py`

**Function:** 
- Launches PeppyMeter as subprocess
- Creates transparent overlay for touch detection
- Detects vertical swipe gestures
- Toggles back to moOde UI on swipe

**Key Features:**
- Minimum swipe distance: 100 pixels
- Maximum swipe time: 0.8 seconds
- Works with both swipe up and swipe down
- Debug output to console

### 2. Installation Script
**File:** `scripts/install-peppymeter-swipe.sh`

**Function:**
- Copies wrapper to system
- Backs up existing .xinitrc
- Updates .xinitrc to use swipe wrapper
- Installs Python dependencies
- Sets permissions

### 3. Emergency Exit Script
**File:** `scripts/emergency-exit-peppymeter.sh`

**Function:**
- Immediate exit from PeppyMeter
- Updates database
- Restarts display service
- Use when stuck in PeppyMeter

---

## Installation Instructions

### Step 1: Get Back to moOde UI (If Stuck Now)

You're currently stuck in PeppyMeter. Here are your options:

#### Option A: SSH from Mac
```bash
# From your Mac terminal:
ssh andre@192.168.2.3
cd moodeaudio-cursor/scripts
bash emergency-exit-peppymeter.sh
```

#### Option B: Connect USB Keyboard
1. Connect USB keyboard to Pi
2. Press **Escape** or **Q** key
3. Should exit PeppyMeter

#### Option C: Reboot Pi
```bash
# If you can SSH:
sudo reboot

# Or physically power cycle the Pi
```

The Pi will boot into moOde UI by default.

---

### Step 2: Install Swipe Gesture Support

Once you're back in moOde UI:

```bash
# SSH to Pi
ssh andre@192.168.2.3

# Navigate to scripts directory
cd moodeaudio-cursor/scripts

# Make scripts executable
chmod +x install-peppymeter-swipe.sh
chmod +x emergency-exit-peppymeter.sh

# Run installation
bash install-peppymeter-swipe.sh
```

**What the installer does:**
1. ✓ Copies swipe wrapper to `/usr/local/bin/`
2. ✓ Backs up your current .xinitrc
3. ✓ Updates .xinitrc to use swipe wrapper
4. ✓ Installs pygame (if not already installed)
5. ✓ Sets up permissions

---

### Step 3: Restart Display Service

After installation:

```bash
sudo systemctl restart localdisplay
```

Wait 5-10 seconds for display to restart.

---

## How to Use

### Toggle TO PeppyMeter:
1. In moOde UI, click the PeppyMeter button (wave icon 🌊)
2. Or use the context menu: ⋯ → "Toggle PeppyMeter"
3. Display switches to blue VU meter

### Toggle FROM PeppyMeter (NEW!):
1. **Swipe UP** on the touchscreen (100+ pixels)
2. Or **Swipe DOWN** on the touchscreen (100+ pixels)
3. Display switches back to moOde UI

**Swipe Requirements:**
- Vertical movement: At least 100 pixels
- Speed: Complete within 0.8 seconds
- Direction: More vertical than horizontal

---

## Troubleshooting

### Swipe Not Working

**Check if wrapper is running:**
```bash
ps aux | grep peppymeter-swipe-wrapper
```

Should show Python process running the wrapper.

**Check .xinitrc:**
```bash
grep "peppymeter-swipe-wrapper" /home/andre/.xinitrc
```

Should contain the wrapper path.

**Check logs:**
```bash
journalctl -u localdisplay -f
```

Look for "Swipe gesture detector initialized" message.

### Touch Not Detected

**Check touch device:**
```bash
ls -la /dev/input/event*
```

**Check permissions:**
```bash
groups andre
```

Should include `input` and `video` groups.

**Add to groups if missing:**
```bash
sudo usermod -a -G input,video andre
sudo reboot
```

### PeppyMeter Doesn't Start

**Test wrapper manually:**
```bash
DISPLAY=:0 python3 /usr/local/bin/peppymeter-swipe-wrapper.py
```

Should launch PeppyMeter with swipe detection.

**Check PeppyMeter installation:**
```bash
ls -la /opt/peppymeter/peppymeter.py
```

Should exist.

---

## Technical Details

### Swipe Detection Algorithm

```python
def detect_swipe(start_pos, end_pos, duration):
    dx = end_pos[0] - start_pos[0]  # Horizontal distance
    dy = end_pos[1] - start_pos[1]  # Vertical distance
    
    # Check minimum vertical distance
    if abs(dy) < 100:
        return None
    
    # Check maximum duration
    if duration > 0.8:
        return None
    
    # Check vertical dominance (1.5x more vertical than horizontal)
    if abs(dy) < abs(dx) * 1.5:
        return None
    
    # Return direction
    return 'up' if dy < 0 else 'down'
```

### Toggle Process

```
1. Swipe detected
   ↓
2. Update database:
   sqlite3 moode-sqlite3.db "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"
   ↓
3. Stop PeppyMeter process
   ↓
4. Restart localdisplay:
   sudo systemctl restart localdisplay
   ↓
5. .xinitrc reads database (peppy_display=0)
   ↓
6. .xinitrc launches Chromium with moOde UI
```

---

## Configuration Options

### Adjust Swipe Sensitivity

Edit `/usr/local/bin/peppymeter-swipe-wrapper.py`:

```python
# Make swipe easier (shorter distance):
SWIPE_MIN_DISTANCE = 80  # Default: 100

# Make swipe slower (more time allowed):
SWIPE_MAX_TIME = 1.0  # Default: 0.8
```

After changes:
```bash
sudo systemctl restart localdisplay
```

### Debug Mode

To see swipe detection debug output:

```bash
# Stop localdisplay
sudo systemctl stop localdisplay

# Run wrapper manually
DISPLAY=:0 python3 /usr/local/bin/peppymeter-swipe-wrapper.py
```

You'll see console output like:
```
Touch down at: (640, 200)
SWIPE UP detected! (distance: 150px, duration: 0.45s)
Switching to moOde UI...
```

---

## Fallback: Emergency Exit

If swipe doesn't work, use the emergency script:

```bash
# SSH to Pi
ssh andre@192.168.2.3

# Run emergency exit
cd moodeaudio-cursor/scripts
bash emergency-exit-peppymeter.sh
```

Or from Mac (one command):
```bash
ssh andre@192.168.2.3 "cd moodeaudio-cursor/scripts && bash emergency-exit-peppymeter.sh"
```

---

## File Locations

```
Workspace (Mac):
└── moodeaudio-cursor/
    └── scripts/
        ├── peppymeter-swipe-wrapper.py      (Source)
        ├── install-peppymeter-swipe.sh      (Installer)
        └── emergency-exit-peppymeter.sh     (Emergency exit)

Raspberry Pi:
├── /usr/local/bin/
│   └── peppymeter-swipe-wrapper.py          (Installed wrapper)
├── /home/andre/
│   └── .xinitrc                             (Updated with wrapper)
└── /opt/peppymeter/
    └── peppymeter.py                        (Original PeppyMeter)
```

---

## User Experience

### Before This Solution ❌
- Click PeppyMeter button → VU meter shows
- **STUCK** - No way to exit!
- Must SSH or reboot to get back

### After This Solution ✅
- Click PeppyMeter button → VU meter shows
- **Swipe up/down** → moOde UI returns
- Click PeppyMeter button → VU meter shows again
- **Perfect toggle experience!**

---

## Next Steps

1. **Right now:** Get back to moOde UI using emergency script
2. **Then:** Run installation script to add swipe gesture support
3. **Test:** Toggle to PeppyMeter, then swipe to exit
4. **Enjoy:** Seamless toggling between moOde UI and PeppyMeter!

---

## Testing Checklist

- [ ] Get back to moOde UI (using emergency script)
- [ ] Run installation script
- [ ] Restart localdisplay service
- [ ] Toggle to PeppyMeter (button works)
- [ ] **Swipe up on display** → Should return to moOde UI
- [ ] Toggle to PeppyMeter again
- [ ] **Swipe down on display** → Should return to moOde UI
- [ ] Verify smooth transitions
- [ ] Test multiple toggles

---

## Benefits

✅ **Natural gesture control** - Swipe is intuitive for touchscreens  
✅ **No extra buttons** - Uses existing display for control  
✅ **Emergency fallback** - SSH script if swipe fails  
✅ **Non-intrusive** - Transparent overlay doesn't interfere with PeppyMeter  
✅ **Reliable detection** - Tuned parameters for accurate swipe recognition  
✅ **Debug support** - Console output for troubleshooting  

---

**Status:** ✅ **Ready to Install**

Run the emergency script to exit PeppyMeter now, then install swipe gesture support for future use!

---

**End of Documentation**
