# THE DEFINITIVE WORKING CONFIGURATION

**This is THE ONLY configuration that works. Use this. Nothing else.**

**Date:** 2025-01-28  
**Status:** ✅ CONFIRMED WORKING  
**Source:** WORKING_CONFIGURATION_PI5.md (the one that says "FUNKTIONIERT PERFEKT!")

---

## Hardware
- Raspberry Pi 5 Model B Rev 1.1
- Waveshare 7.9" HDMI LCD (1280x400 native)
- Moode Audio

---

## File 1: /boot/firmware/cmdline.txt

**EXACT CONTENT (ONE LINE):**
```
console=serial0,115200 console=tty1 root=PARTUUID=CHANGE_ME rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
```

**CRITICAL PARTS:**
- `video=HDMI-A-2:400x1280M@60,rotate=90` - MUST be present
- `HDMI-A-2` - Correct HDMI port for Pi 5
- `400x1280M@60,rotate=90` - Display starts Portrait, then rotates

**NOTE:** Replace `CHANGE_ME` with actual PARTUUID from your SD card.

---

## File 2: /boot/firmware/config.txt

**BASE:** Use moOde's managed config.txt (from backup)

**ADD TO [pi5] SECTION:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
display_rotate=0
```

**ENSURE IN [all] SECTION:**
```ini
[all]
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 480 60 6 0 0 0
hdmi_force_hotplug=1
hdmi_drive=2
```

**NOTE:** `hdmi_cvt=1280 480` (480, not 400!) - This is what the working config had.

---

## How to Apply

1. **Backup current config:**
   ```bash
   cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
   cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
   ```

2. **Apply cmdline.txt:**
   - Replace entire file with the ONE LINE above
   - Replace `CHANGE_ME` with your PARTUUID

3. **Apply config.txt:**
   - Keep moOde's base config
   - Add [pi5] section with `dtoverlay=vc4-kms-v3d-pi5,noaudio`
   - Ensure `hdmi_cvt=1280 480 60 6 0 0 0` is present

---

## Why This Works

1. **Video parameter:** `400x1280M@60,rotate=90` makes display start in Portrait, then xrandr rotates it to Landscape
2. **KMS overlay:** `vc4-kms-v3d-pi5,noaudio` is Pi 5 specific (not generic)
3. **HDMI CVT:** `1280 480` creates the custom mode (480 height, not 400)
4. **xrandr rotation:** Applied in xinitrc to rotate from 400x1280 to 1280x400

---

## What NOT to Do

- ❌ Don't use `video=HDMI-A-2:1280x400M@60` (wrong, doesn't work)
- ❌ Don't use `hdmi_cvt=1280 400` (wrong, use 480)
- ❌ Don't remove the video parameter
- ❌ Don't use generic `dtoverlay=vc4-kms-v3d` without `-pi5`

---

## Verification

After applying, verify:
```bash
# Check cmdline.txt
grep "video=HDMI-A-2:400x1280M@60,rotate=90" /boot/firmware/cmdline.txt

# Check config.txt
grep "dtoverlay=vc4-kms-v3d-pi5" /boot/firmware/config.txt
grep "hdmi_cvt.*1280.*480" /boot/firmware/config.txt
```

---

## Backup Location

Backup files are in:
`sd_card_config/backups/20251128_010229/`

---

**This is THE configuration. Use this. Nothing else.**

