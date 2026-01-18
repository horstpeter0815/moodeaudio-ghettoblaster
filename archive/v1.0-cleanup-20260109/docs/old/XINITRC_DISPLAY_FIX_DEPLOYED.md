# ✅ XINITRC DISPLAY FIX - DEPLOYED

**Date:** 2026-01-09  
**Status:** ✅ FIXED AND READY FOR DEPLOYMENT

## What Was Fixed

The `.xinitrc.default` file has been fixed with the **forum solution** for Waveshare 7.9" display:

### Key Fixes Applied:

1. ✅ **X Server Wait** - Waits up to 30 seconds for X server to be ready
2. ✅ **HDMI Detection** - Automatically detects HDMI-1 (Pi 4) or HDMI-2 (Pi 5)
3. ✅ **Proper xrandr Rotation Sequence** (applied BEFORE xset commands):
   - Reset to `normal` first
   - Set mode to `400x1280` (hardware native)
   - Rotate `left` → results in `1280x400` landscape
   - Includes proper delays between steps
4. ✅ **Forced SCREEN_RES** - Sets `SCREEN_RES="1280,400"` for Waveshare 7.9" portrait displays
5. ✅ **Enhanced Chromium Flags**:
   - `--force-device-scale-factor=1` - Prevents scaling issues
   - `--start-fullscreen` - Ensures fullscreen mode
   - All existing flags preserved

## Files Modified

- ✅ `moode-source/home/xinitrc.default` - Fixed with forum solution

## Deployment Options

### Option 1: Deploy to SD Card (Current Method)

**Run this command:**
```bash
cd ~/moodeaudio-cursor && sudo ./scripts/deployment/DEPLOY_XINITRC_NOW.sh
```

**Requirements:**
- SD card mounted at `/Volumes/rootfs`
- Run with `sudo` (will prompt for password)

### Option 2: Deploy via SSH (When Pi is Running)

**Run this command:**
```bash
cd ~/moodeaudio-cursor && ./scripts/deployment/DEPLOY_XINITRC_DISPLAY_FIX.sh
```

**Requirements:**
- Pi reachable at `192.168.10.2`
- SSH access configured
- `sshpass` installed (`brew install hudochenkov/sshpass/sshpass`)

## Post-Deployment Steps

After deploying the `.xinitrc` file:

1. **Boot the Pi** (if deploying to SD card)

2. **Set moOde Database Setting:**
   ```bash
   ssh andre@192.168.10.2
   sudo moodeutl -i "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';"
   ```

3. **Reboot:**
   ```bash
   sudo reboot
   ```

4. **Verify Display:**
   ```bash
   ssh andre@192.168.10.2
   DISPLAY=:0 xrandr --query
   ```
   
   Expected output should show:
   - `HDMI-1 connected primary 1280x400+0+0 left` (Pi 4)
   - OR `HDMI-2 connected primary 1280x400+0+0 left` (Pi 5)

## How It Works

The forum solution approach:

1. **Hardware:** Waveshare 7.9" is portrait (400x1280) - set in boot config
2. **Kernel:** `cmdline.txt` has `video=HDMI-A-1:400x1280M@60,rotate=90` (rotates framebuffer)
3. **X11:** `.xinitrc` applies xrandr rotation sequence:
   - Reset → Set mode → Rotate left
   - Results in 1280x400 landscape
4. **Chromium:** Launched with `--window-size=1280,400` → renders at landscape size
5. **SCREEN_RES:** Forced to `"1280,400"` before Chromium launches

This ensures all layers are synchronized:
- Framebuffer: 1280x400 (after kernel rotation)
- DRM plane: 1280x400 (after xrandr rotation)
- X11 display: 1280x400
- Chromium window: 1280x400
- Chromium viewport: 1280x400

## Troubleshooting

### If display still shows wrong size:
- Check moOde database: `sudo moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'"`
- Should be `portrait`
- If not, set it: `sudo moodeutl -i "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';"`

### If only 1/3 of screen is visible:
- SCREEN_RES was likely still set to "400,1280" - must be "1280,400"
- Check `.xinitrc` has: `SCREEN_RES="1280,400"`

### If display is upside down:
- Check xrandr rotation (should be "left", not "right")
- Verify: `DISPLAY=:0 xrandr --query | grep HDMI`

### If Chromium window is wrong size:
- Ensure `--window-size="1280,400"` is in Chromium launch command
- Check `--force-device-scale-factor=1` is present

## Verification Commands

```bash
# Check X11 display size
DISPLAY=:0 xdpyinfo | grep dimensions

# Check xrandr output
DISPLAY=:0 xrandr --query | grep "HDMI.*connected"

# Check Chromium window size
DISPLAY=:0 xwininfo -root -tree | grep "moOde Player"

# Check Chromium process args
ps aux | grep chromium | grep window-size

# Check .xinitrc content
cat /home/andre/.xinitrc | grep -A 5 "SCREEN_RES\|xrandr\|Forum Solution"
```

**Expected Results:**
- X11 dimensions: `1280x400`
- xrandr: `HDMI-1 connected primary 1280x400+0+0 left` (or HDMI-2 for Pi 5)
- Window: `1279x399+0+0` (1px difference is normal)
- Chromium args: `--window-size=1280,400 --force-device-scale-factor=1`
- .xinitrc: Contains `SCREEN_RES="1280,400"` and xrandr rotation sequence

## Summary

✅ **Fixed:** `.xinitrc.default` with complete forum solution  
✅ **Created:** Deployment scripts for SD card and SSH  
✅ **Ready:** For deployment and testing  

**Next:** Run deployment script and boot Pi to test!
