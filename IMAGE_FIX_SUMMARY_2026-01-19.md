# moOde Image Fix Summary
**Date:** January 19, 2026  
**Image:** moode-r1001-arm64-20260119_132811-lite-FIXED.img  
**Status:** ✅ Ready to burn

---

## Fixes Applied

### 1. Boot Configuration (`/boot/firmware/cmdline.txt`)

**Changed from:**
```
console=serial0,115200 console=tty1 root=PARTUUID=1f100fd5-02 rootfstype=ext4 fsck.repair=yes rootwait resize fbcon=rotate:3
```

**Changed to:**
```
console=tty3 root=PARTUUID=1f100fd5-02 rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3 video=HDMI-A-1:1280x400@60 logo.nologo vt.global_cursor_default=0
```

**Why:**
- Added `video=HDMI-A-1:1280x400@60` - Sets correct framebuffer resolution for 1280x400 landscape display
- Changed console to `tty3` - Reduces boot messages
- Added `quiet loglevel=3` - Clean boot experience
- Added `logo.nologo` - Removes boot logo
- Added `vt.global_cursor_default=0` - Hides cursor
- Removed `fbcon=rotate:3` - Not needed, display is natively landscape

---

### 2. System Configuration (`/boot/firmware/config.txt`)

**Fixed settings:**
```
arm_boost=1                    # Was 0, must be 1 (performance boost)
hdmi_force_edid_audio=0        # Was 1, must be 0 (disable HDMI audio)
dtparam=audio=off              # Confirmed (disable onboard audio)
dtoverlay=hifiberry-amp100     # Confirmed (HiFiBerry AMP100)
```

**Why:**
- `arm_boost=1` - Required for performance (mandatory per system rules)
- `hdmi_force_edid_audio=0` - HiFiBerry AMP100 is the audio device, not HDMI
- `dtparam=audio=off` - Disable onboard audio to prevent conflicts
- `dtoverlay=hifiberry-amp100` - Enable HiFiBerry AMP100 audio HAT

---

### 3. moOde Database Configuration (`/var/local/www/db/moode-sqlite3.db`)

**Fixed settings:**
| Parameter | Old Value | New Value | Why |
|-----------|-----------|-----------|-----|
| `adevname` | Pi HDMI 1 | HiFiBerry AMP100 | Correct audio device |
| `i2sdevice` | None | HiFiBerry AMP100 | Enable I2S device |
| `cardnum` | 0 | 1 | HiFiBerry is card 1 |
| `alsa_output_mode` | iec958 | plughw | Correct ALSA mode |
| `local_display` | 0 | 1 | Enable local display |
| `camilladsp` | off | bose_wave_filters.yml | Enable Bose Wave filters |
| `cdsp_fix_playback` | - | Yes | Fix CamillaDSP playback |
| `hdmi_scn_orient` | landscape | landscape | ✅ Already correct |

---

### 4. ALSA Configuration (`/etc/alsa/conf.d/_audioout.conf`)

**Changed from:**
```
slave.pcm "plughw:0,0"
```

**Changed to:**
```
slave.pcm "plughw:1,0"
```

**Why:**
- HiFiBerry AMP100 is audio card 1, not card 0
- Card 0 is the (disabled) onboard audio

---

## Display Configuration

### Resolution and Orientation
- **Physical display:** 1280x400 pixels (landscape)
- **Boot screen:** Set by `video=HDMI-A-1:1280x400@60` in cmdline.txt
- **moOde UI:** Uses same resolution, reads orientation from database
- **Orientation:** `hdmi_scn_orient=landscape` in database
- **X11 rotation:** Handled automatically by `.xinitrc` reading database

### How It Works
1. **During boot:** cmdline.txt sets framebuffer to 1280x400 landscape
2. **X11 starts:** `.xinitrc` reads database and applies xrandr rotation if needed
3. **moOde UI:** Chromium opens with `--window-size=1280,400` in landscape
4. **Database:** `hdmi_scn_orient=landscape` tells `.xinitrc` not to rotate

---

## Audio Configuration

### HiFiBerry AMP100
- **Device:** HiFiBerry AMP100 (I2S audio HAT)
- **ALSA card:** Card 1 (plughw:1,0)
- **Output mode:** plughw
- **CamillaDSP:** Enabled with Bose Wave filters

### Disabled Audio
- **Onboard audio:** Disabled via `dtparam=audio=off`
- **HDMI audio:** Disabled via `hdmi_force_edid_audio=0`
- **Bluetooth audio:** (check if needed)

---

## Burning the Image

### Option 1: Use the provided script
```bash
cd /Users/andrevollmer/moodeaudio-cursor
./BURN_FIXED_IMAGE.sh
```

### Option 2: Manual burn
```bash
# Unmount SD card
diskutil unmountDisk force /dev/disk4

# Burn image (5-10 minutes)
sudo dd if=/Users/andrevollmer/moodeaudio-cursor/imgbuild/deploy/moode-r1001-arm64-20260119_132811-lite-FIXED.img of=/dev/rdisk4 bs=1m conv=sync status=progress

# Sync and eject
sync
diskutil eject /dev/disk4
```

---

## First Boot

### What to Expect
1. **Boot screen:** Should be landscape 1280x400, no rotation issues
2. **moOde UI:** Should load in landscape orientation
3. **Display:** Local display should be enabled automatically
4. **Audio:** HiFiBerry AMP100 should be the default audio device
5. **Filters:** Bose Wave CamillaDSP filters should be active

### Verification Steps
```bash
# Check display orientation
moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'"
# Should show: landscape

# Check audio device
moodeutl -q "SELECT value FROM cfg_system WHERE param='adevname'"
# Should show: HiFiBerry AMP100

# Check ALSA card
aplay -l
# Should show: card 1: snd_rpi_hifiberry_dacplus

# Check CamillaDSP
moodeutl -q "SELECT value FROM cfg_system WHERE param='camilladsp'"
# Should show: bose_wave_filters.yml
```

---

## Configuration Files Location

### On SD Card (after burning)
- `/boot/firmware/cmdline.txt` - Boot parameters with video parameter
- `/boot/firmware/config.txt` - System configuration
- `/var/local/www/db/moode-sqlite3.db` - moOde database
- `/etc/alsa/conf.d/_audioout.conf` - ALSA audio output configuration
- `/home/pi/.xinitrc` - X11 startup script (reads database)

### In Repository
- `/Users/andrevollmer/moodeaudio-cursor/imgbuild/deploy/moode-r1001-arm64-20260119_132811-lite-FIXED.img` - Fixed image
- `/Users/andrevollmer/moodeaudio-cursor/BURN_FIXED_IMAGE.sh` - Burn script

---

## Troubleshooting

### Display Issues
- **Boot screen wrong orientation:** Check cmdline.txt has `video=HDMI-A-1:1280x400@60`
- **moOde UI wrong orientation:** Check database `hdmi_scn_orient=landscape`
- **Display not showing:** Check `local_display=1` in database

### Audio Issues
- **No audio:** Check `aplay -l` shows HiFiBerry as card 1
- **Wrong device:** Check database has `adevname=HiFiBerry AMP100`
- **ALSA errors:** Check `/etc/alsa/conf.d/_audioout.conf` has `plughw:1,0`

### First Boot Issues
- **Hangs on boot:** Remove `resize` from cmdline.txt if it hangs
- **Black screen:** Check HDMI cable and power supply
- **No network:** Check if NetworkManager is running

---

## Changes Summary

### Files Modified
1. `/boot/firmware/cmdline.txt` - Added video parameter
2. `/boot/firmware/config.txt` - Fixed arm_boost and hdmi_force_edid_audio
3. `/var/local/www/db/moode-sqlite3.db` - Fixed audio and display settings
4. `/etc/alsa/conf.d/_audioout.conf` - Fixed ALSA output device

### Configuration Changes
- ✅ Display: 1280x400 landscape
- ✅ Audio: HiFiBerry AMP100 on card 1
- ✅ Filters: Bose Wave CamillaDSP filters enabled
- ✅ Performance: arm_boost enabled
- ✅ Local display: Enabled
- ✅ HDMI audio: Disabled
- ✅ Onboard audio: Disabled

---

## Next Steps

1. **Burn the image** using `./BURN_FIXED_IMAGE.sh`
2. **Insert SD card** into Raspberry Pi 5
3. **Power on** and wait for first boot
4. **Verify display** shows in correct orientation
5. **Test audio** with moOde playback (start at volume 0, gradually increase)
6. **Check network** connectivity
7. **Access moOde** via browser at `http://moode.local`

---

**Status:** ✅ Ready to burn  
**Tested:** Image mounted, configurations verified  
**Documentation:** This file + WISSENSBASIS/ for future reference
