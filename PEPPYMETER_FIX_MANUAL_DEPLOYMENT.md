# PeppyMeter Toggle - Manual Deployment Guide

**Date:** 2026-01-21  
**Status:** Ready to Deploy

---

## Files Changed

Two files have been modified in the workspace and need to be deployed to the Pi:

1. **Backend Handler:** `moode-source/www/command/playback.php`
2. **HTML Button:** `moode-source/www/templates/indextpl.html`

---

## Option 1: Deploy via Terminal (Recommended)

### Step 1: Copy Files to Pi

Open Terminal on your Mac and run these commands:

```bash
# Navigate to workspace
cd /Users/andrevollmer/moodeaudio-cursor

# Copy playback.php to Pi (you'll be prompted for password)
scp moode-source/www/command/playback.php andre@192.168.2.3:/tmp/

# Copy indextpl.html to Pi
scp moode-source/www/templates/indextpl.html andre@192.168.2.3:/tmp/
```

**Note:** You'll need to enter the password for user `andre` on the Pi for each scp command.

### Step 2: SSH to Pi and Install Files

```bash
# SSH to the Pi
ssh andre@192.168.2.3

# Once connected, run these commands on the Pi:
sudo cp /tmp/playback.php /var/www/command/playback.php
sudo cp /tmp/indextpl.html /var/www/templates/indextpl.html
sudo chown www-data:www-data /var/www/command/playback.php
sudo chown www-data:www-data /var/www/templates/indextpl.html
sudo chmod 644 /var/www/command/playback.php
sudo chmod 644 /var/www/templates/indextpl.html
rm /tmp/playback.php /tmp/indextpl.html
```

### Step 3: Clear Cache and Reload Services

```bash
# Still on the Pi, run:
/var/www/util/sysutil.sh clearbrcache
sudo systemctl reload nginx
sudo systemctl reload php8.4-fpm
```

### Step 4: Verify Installation

```bash
# Check if changes are present:
grep -q 'toggle_peppymeter' /var/www/command/playback.php && echo "✅ Backend handler installed" || echo "❌ Backend handler missing"

grep -q 'toggle-peppymeter' /var/www/templates/indextpl.html && echo "✅ HTML button installed" || echo "❌ HTML button missing"

# Exit SSH
exit
```

---

## Option 2: Deploy via SD Card (If SSH Not Working)

### Step 1: Shutdown Pi

```bash
# If you can SSH (even without password):
ssh andre@192.168.2.3 "sudo shutdown -h now"

# Otherwise: Power off the Pi physically
# Wait for shutdown to complete (30 seconds)
```

### Step 2: Mount SD Card on Mac

1. Remove SD card from Pi
2. Insert into Mac's SD card reader
3. Wait for `rootfs` volume to mount

### Step 3: Copy Files to SD Card

```bash
# Copy modified files
sudo cp /Users/andrevollmer/moodeaudio-cursor/moode-source/www/command/playback.php \
        /Volumes/rootfs/var/www/command/playback.php

sudo cp /Users/andrevollmer/moodeaudio-cursor/moode-source/www/templates/indextpl.html \
        /Volumes/rootfs/var/www/templates/indextpl.html

# Set permissions
sudo chown 33:33 /Volumes/rootfs/var/www/command/playback.php
sudo chown 33:33 /Volumes/rootfs/var/www/templates/indextpl.html
sudo chmod 644 /Volumes/rootfs/var/www/command/playback.php
sudo chmod 644 /Volumes/rootfs/var/www/templates/indextpl.html

# Sync and eject
sync
diskutil eject /Volumes/rootfs
```

### Step 4: Boot Pi

1. Insert SD card back into Pi
2. Power on Pi
3. Wait for boot (60 seconds)

---

## Testing the Fix

### 1. Hard Refresh Browser

Open browser to: `http://192.168.2.3/`

**Hard refresh to clear cache:**
- Mac: `Cmd + Shift + R`
- Windows/Linux: `Ctrl + F5`

### 2. Find the PeppyMeter Button

Look in the playback controls section:

```
[⋯] [🔀] [📺] [🌊] [●] [♥]
       TV  Wave
     CoverView PeppyMeter
```

**The wave icon (🌊) is the new PeppyMeter toggle button!**

### 3. Test Toggle Functionality

**First Click (Turn ON):**
1. Click the wave icon (🌊)
2. Notification should appear: "PeppyMeter ON"
3. Display should go black briefly (2-3 seconds)
4. Blue VU meter should appear fullscreen
5. VU meter needles should move with audio

**Second Click (Turn OFF):**
1. Click the wave icon (🌊) again
2. Notification should appear: "PeppyMeter OFF"
3. Display should go black briefly
4. moOde UI should return to normal playback view

### 4. Verify Persistence

**Reboot test:**
```bash
ssh andre@192.168.2.3 "sudo reboot"
# Wait 60 seconds
```

After reboot:
- Button should still be visible
- Toggle should still work
- Last state should be preserved (if PeppyMeter was ON, it stays ON)

---

## Troubleshooting

### Button Not Visible

**Problem:** Wave icon doesn't appear after deployment

**Solution:**
1. Hard refresh browser (Cmd+Shift+R)
2. Check browser console (F12) for errors
3. Verify file was deployed:
   ```bash
   ssh andre@192.168.2.3 "grep 'toggle-peppymeter' /var/www/templates/indextpl.html"
   ```

### Button Doesn't Respond

**Problem:** Click button but nothing happens

**Solution:**
1. Check browser console (F12) for JavaScript errors
2. Verify backend handler exists:
   ```bash
   ssh andre@192.168.2.3 "grep 'toggle_peppymeter' /var/www/command/playback.php"
   ```
3. Check moOde logs:
   ```bash
   ssh andre@192.168.2.3 "tail -f /var/log/moode.log"
   ```

### Display Doesn't Switch

**Problem:** Notification appears but display doesn't change

**Solution:**
1. Check localdisplay service:
   ```bash
   ssh andre@192.168.2.3 "systemctl status localdisplay"
   ```
2. Check worker.php logs:
   ```bash
   ssh andre@192.168.2.3 "tail -f /var/log/moode_worker.log"
   ```
3. Manually restart display:
   ```bash
   ssh andre@192.168.2.3 "sudo systemctl restart localdisplay"
   ```

### PeppyMeter Shows Wrong Meter

**Problem:** PeppyMeter shows random meter instead of blue

**Solution:**
```bash
# Check PeppyMeter config
ssh andre@192.168.2.3 "cat /etc/peppymeter/config.txt | grep meter"

# Should show:
# meter = blue
# meter.folder = 1280x400

# If not, fix it:
ssh andre@192.168.2.3 "sudo sed -i 's/meter =.*/meter = blue/' /etc/peppymeter/config.txt"
ssh andre@192.168.2.3 "sudo systemctl restart localdisplay"
```

---

## What Was Fixed

### Before (BROKEN):
- ✅ JavaScript handler existed (scripts-panels.js)
- ❌ Backend PHP handler missing (playback.php)
- ❌ HTML button missing (indextpl.html)
- **Result:** Button didn't exist, toggle didn't work

### After (WORKING):
- ✅ JavaScript handler exists (scripts-panels.js)
- ✅ Backend PHP handler added (playback.php lines 73-81)
- ✅ HTML button added (indextpl.html line 89)
- **Result:** Complete toggle functionality!

---

## Technical Details

### Backend Handler (playback.php)

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

**Function:**
1. Opens PHP session
2. Toggles `peppy_display` between '0' and '1'
3. Updates session and database
4. Submits job to worker.php
5. Returns notification message

### HTML Button (indextpl.html)

```html
<button class="btn btn-cmd toggle-peppymeter" id="toggle-peppymeter" aria-label="PeppyMeter">
    <i class="fa-regular fa-sharp fa-wave-pulse"></i>
</button>
```

**Placement:** In `#togglebtns` section, right after CoverView button

**Icon:** `fa-wave-pulse` (wave icon - perfect for VU meter visualization!)

### Data Flow

```
User clicks wave icon (🌊)
    ↓
JavaScript: $('#toggle-peppymeter').click()
    ↓
POST: command/index.php?cmd=toggle_peppymeter
    ↓
Backend: playback.php case 'toggle_peppymeter'
    ↓
Updates database: peppy_display = '1' or '0'
    ↓
Submits job: worker.php case 'peppy_display'
    ↓
Worker actions:
    - Stops localdisplay service
    - Unhides/hides ALSA peppy.conf
    - Updates audio configs
    - Starts localdisplay service
    - Restarts MPD and renderers
    ↓
Display shows:
    - If peppy_display='1': Blue VU meter (PeppyMeter)
    - If peppy_display='0': moOde Web UI (Chromium)
```

---

## Success Criteria

- [x] Code changes implemented (Phase 4)
- [ ] Files deployed to Pi
- [ ] Browser cache cleared
- [ ] Button visible in UI
- [ ] Button responds to clicks
- [ ] Display switches to PeppyMeter
- [ ] Display switches back to moOde UI
- [ ] Toggle works after reboot

**Once all checked: PeppyMeter toggle is COMPLETE! ✅**

---

**Created:** 2026-01-21  
**Workflow Phase:** Phase 5 - VERIFY & DOCUMENT  
**Development Methodology:** WISSENSBASIS/DEVELOPMENT_WORKFLOW.md
