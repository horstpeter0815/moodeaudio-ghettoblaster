# Post-Boot Testing Guide

**Pi 5 has booted - Now verify the configuration!**

---

## Quick Visual Check

1. **Look at the display:**
   - ✅ **GOOD:** Display shows image in **landscape** (1280x400) - wide format
   - ❌ **BAD:** Display shows image in **portrait** (400x1280) - tall format
   - ❌ **BAD:** Display is blank or shows error

2. **Check if Moode UI is visible:**
   - If Moode has started, you should see the web interface
   - Window should fit the display correctly (no cut-off)

---

## SSH Testing (Recommended)

### Step 1: Connect to Pi
```bash
ssh moode@<pi-ip-address>
# or
ssh pi@<pi-ip-address>
```

### Step 2: Run Quick Test
Copy and run this test script on the Pi:

```bash
# Quick config check
echo "=== cmdline.txt ==="
cat /boot/firmware/cmdline.txt 2>/dev/null || cat /boot/cmdline.txt
echo ""
echo "=== config.txt (HDMI section) ==="
grep -E "hdmi_|display_rotate" /boot/firmware/config.txt 2>/dev/null || grep -E "hdmi_|display_rotate" /boot/config.txt
echo ""
echo "=== Framebuffer ==="
fbset -s 2>/dev/null | grep geometry || echo "fbset not available"
echo ""
echo "=== xrandr (if X11 running) ==="
DISPLAY=:0 xrandr 2>/dev/null | grep -E "HDMI|connected|1280x400" || echo "X11 not running"
```

### Step 3: Check Display Status
```bash
# Check DRM devices
ls -la /sys/class/drm/card*/status

# Check HDMI power
vcgencmd display_power 2>/dev/null || echo "Command not available"
```

---

## Expected Results

### ✅ SUCCESS Indicators:
- `cmdline.txt`: **NO** `video=HDMI-A-2:400x1280M@60,rotate=90` parameter
- `config.txt`: Contains `hdmi_cvt=1280 400 60 6 0 0 0`
- `config.txt`: Contains `display_rotate=0`
- Display shows image in **landscape** (wide, not tall)
- Framebuffer shows `geometry 1280 400` (if fbset available)
- xrandr shows `HDMI-2 connected 1280x400+0+0` (no rotation)

### ❌ FAILURE Indicators:
- Display is blank
- Display shows portrait (tall) instead of landscape (wide)
- `cmdline.txt` still has `video=` parameter
- Framebuffer shows wrong resolution

---

## If Display is Wrong

### Option 1: Check Moode Settings
1. Access Moode web UI (if available)
2. Go to **System** → **Display**
3. Set **HDMI Screen Orientation** to `landscape`
4. Save and reboot

### Option 2: Manual xinitrc Fix (if needed)
If Moode doesn't handle rotation automatically:

```bash
# SSH into Pi
# Check current xinitrc
cat ~/.xinitrc

# If it has forced rotation, remove it:
# Remove line: DISPLAY=:0 xrandr --output HDMI-2 --rotate left
```

### Option 3: Rollback
If nothing works, restore from backup:

```bash
# On Mac, mount SD card
# Copy backup files back:
cp sd_card_config/backups/20251128_010229/config.txt.backup /Volumes/bootfs/config.txt
cp sd_card_config/backups/20251128_010229/cmdline.txt.backup /Volumes/bootfs/cmdline.txt
```

---

## Next Steps After Verification

1. **If display is correct:**
   - ✅ Configuration successful!
   - Test touchscreen (if applicable)
   - Test Peppy Meter (if applicable)
   - Enjoy your clean HDMI setup!

2. **If display needs adjustment:**
   - Check Moode display settings
   - Verify xinitrc doesn't have forced rotation
   - Report what you see for further troubleshooting

---

## Test Script

You can also copy the test script to the Pi and run it:

```bash
# On Mac, copy script to Pi:
scp sd_card_config/test_display_after_boot.sh moode@<pi-ip>:/tmp/

# On Pi, run it:
chmod +x /tmp/test_display_after_boot.sh
/tmp/test_display_after_boot.sh
```

---

**Status:** Waiting for test results...

