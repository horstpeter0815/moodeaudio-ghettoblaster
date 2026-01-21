# moOde Audio v1.0 - Complete Working Configuration
**Date:** 2026-01-21
**Status:** ✅ FULLY WORKING - Tested and Verified

## Quick Start
This is a **complete, tested, working configuration** for moOde Audio 10.0.2 on Raspberry Pi 5 with:
- HiFiBerry AMP100 audio output
- 1280x400 landscape touchscreen display (WaveShare)
- CamillaDSP with Bose Wave filters
- WiFi network configuration
- 6 curated radio stations

## Hardware
- **Raspberry Pi 5** (8GB)
- **HiFiBerry AMP100** audio HAT
- **1280x400 touchscreen** (WaveShare, 400x1280 native, rotated to landscape)
- **SD Card:** 32GB+ recommended

## Installation

### 1. Download and Burn Image
```bash
# Download moOde 10.0.2 from https://moodeaudio.org/
# File: 2025-12-18-moode-r1002-arm64-lite.img

# Burn to SD card (macOS)
diskutil list  # Find your SD card (e.g., /dev/disk4)
diskutil unmountDisk /dev/disk4
sudo dd if=2025-12-18-moode-r1002-arm64-lite.img of=/dev/rdisk4 bs=1m
```

### 2. Apply Configuration Files
Mount the SD card and copy these files:

**Boot Partition (`/Volumes/bootfs/`):**
- Copy `backups/moode-10.0.2-working-2026-01-20/boot/cmdline.txt`
- Copy `backups/moode-10.0.2-working-2026-01-20/boot/config.txt`
- Create empty file: `ssh` (enables SSH)

**Root Partition (`/Volumes/rootfs/`):**
```bash
# WiFi configuration
sudo bash -c 'cat > /Volumes/rootfs/etc/NetworkManager/system-connections/NAMYANG2.nmconnection << "EOF"
[connection]
id=NAM YANG 2
type=wifi
autoconnect=true

[wifi]
ssid=NAM YANG 2
mode=infrastructure

[wifi-security]
key-mgmt=wpa-psk
psk=YOUR_WIFI_PASSWORD

[ipv4]
method=auto

[ipv6]
method=auto
EOF'
sudo chmod 600 /Volumes/rootfs/etc/NetworkManager/system-connections/NAMYANG2.nmconnection

# Hostname
echo "moode" | sudo tee /Volumes/rootfs/etc/hostname
```

### 3. First Boot Setup
```bash
# SSH into Pi (default password: moode)
ssh andre@moode.local
# Password: 0815 (after initial setup)

# Install touch calibration
sudo mkdir -p /usr/share/X11/xorg.conf.d
sudo bash -c 'cat > /usr/share/X11/xorg.conf.d/40-libinput-touchscreen.conf << "EOF"
Section "InputClass"
    Identifier "libinput touchscreen calibration"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "TransformationMatrix" "0 -1 1 1 0 0 0 0 1"
EndSection
EOF'

# Copy v1.0 .xinitrc with touch support
sudo cp /path/to/backup/.xinitrc /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc

# Install audio fix service
sudo cp /path/to/fix-audioout-cdsp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fix-audioout-cdsp.service

# Set database orientation
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient'"

# Reboot
sudo reboot
```

## Configuration Details

### Display Configuration
**Resolution:** 1280x400 landscape (physical display is 400x1280, rotated 90° left)

**Key Settings:**
- `cmdline.txt`: `video=HDMI-A-1:400x1280M@60,rotate=90`
- `config.txt`: `hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0`
- Database: `hdmi_scn_orient='portrait'` (yes, portrait! This triggers the xrandr rotation)
- `.xinitrc`: Applies `xrandr --output HDMI-2 --rotate left` when database says 'portrait'

**Why "portrait" in database produces landscape:**
- The display is physically 400x1280 (portrait)
- cmdline.txt sets framebuffer to match: 400x1280 with rotate=90
- When database says "portrait", .xinitrc applies "rotate left" via xrandr
- Result: 1280x400 landscape display

### Touch Calibration
**Transformation Matrix:** `"0 -1 1 1 0 0 0 0 1"`

This matrix transforms touch coordinates to match the 90° left rotation:
- Maps X → Y
- Maps Y → inverted X
- Corrects for display rotation

### Audio Configuration
**Device:** HiFiBerry AMP100 (ALSA card 0, `plughw:0,0`)

**Chain:** MPD → CamillaDSP → HiFiBerry AMP100

**Critical Files:**
- `/etc/alsa/conf.d/_audioout.conf`: Routes MPD to CamillaDSP
- `/usr/share/camilladsp/working_config.yml`: Active filter (Bose Wave)
- `/etc/systemd/system/fix-audioout-cdsp.service`: Fixes audio routing 15s after boot

**Why the fix-audioout service?**
moOde's `worker.php` has a bug where it sometimes detects HiFiBerry as `ALSA_EMPTY_CARD` and resets audio to "Pi HDMI 1". The service waits 15 seconds (after worker.php finishes), then fixes `_audioout.conf` to use the correct device.

### CamillaDSP Filters
**Location:** `/usr/share/camilladsp/configs/bose_wave_*.yml`

**Active Filter:** `bose_wave_physics_optimized.yml`
- 20-band parametric EQ
- Room correction
- Waveguide compensation for Bose Wave speakers

**To switch filters:** Edit `/usr/share/camilladsp/working_config.yml` or use moOde UI

### Radio Stations
6 curated stations in `/var/lib/mpd/music/RADIO/`:
1. Deutschlandfunk (Köln)
2. Deutschlandfunk (Kultur)
3. Deutschlandfunk (Nova)
4. FM4 (Austria)
5. Radio 1 (Switzerland)
6. Radio Ton (Heilbronn)

## Network Configuration
**WiFi:** NAM YANG 2 (configured in NetworkManager)
**Ethernet:** DHCP auto-configuration
**USB-C:** Gadget mode enabled (for USB networking)

## Complete File Reference

### Boot Configuration Files
**`/boot/firmware/cmdline.txt`:**
```
console=tty3 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3 video=HDMI-A-1:400x1280M@60,rotate=90 logo.nologo vt.global_cursor_default=0
```

**`/boot/firmware/config.txt`:** (See `backups/moode-10.0.2-working-2026-01-20/boot/config.txt`)

**Critical config.txt settings:**
- `arm_boost=1` (MANDATORY)
- `dtparam=audio=off` (MANDATORY - disables onboard audio)
- `dtoverlay=vc4-kms-v3d-pi5,noaudio` (MANDATORY - KMS for Pi 5)
- `hdmi_force_edid_audio=0` (MANDATORY - no HDMI audio)
- `dtoverlay=hifiberry-amp100` (HiFiBerry driver)
- `dtoverlay=ft6236` (WaveShare touch driver)

### Runtime Configuration Files
**`.xinitrc`:** (See `backups/moode-10.0.2-working-2026-01-20/home/.xinitrc`)
- Sets framebuffer: `fbset -g 1280 400 1280 400 16`
- Reads database orientation
- Applies xrandr rotation if needed
- Launches Chromium with `--touch-events=enabled`

**Touch calibration:** (See `backups/moode-10.0.2-working-2026-01-20/etc/40-libinput-touchscreen.conf`)

**Audio fix service:** (See `backups/moode-10.0.2-working-2026-01-20/systemd/fix-audioout-cdsp.service`)

## Database Settings
**Key cfg_system values:**
```sql
hdmi_scn_orient = 'portrait'
local_display = '1'
i2sdevice = 'HiFiBerry Amp2/4'
adevname = 'HiFiBerry Amp2/4'
cardnum = '0'
alsa_output_mode = 'plughw'
camilladsp = 'bose_wave_physics_optimized.yml'
camilladsp_volume_sync = 'on'
```

## Testing Checklist
After installation, verify:
- [ ] Boot screen displays in 1280x400 landscape
- [ ] moOde UI loads in 1280x400 landscape
- [ ] Touch works correctly (no left/right inversion)
- [ ] Audio plays through HiFiBerry (not HDMI)
- [ ] CamillaDSP is active (check moOde UI)
- [ ] Radio stations are visible and playable
- [ ] WiFi connects automatically
- [ ] Volume control works (MPD 0-100%)

## Troubleshooting

### Display in wrong orientation
- Check database: `sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'"`
- Should be: `portrait`
- Restart display: `sudo systemctl restart localdisplay`

### Touch not working or inverted
- Check calibration file exists: `/usr/share/X11/xorg.conf.d/40-libinput-touchscreen.conf`
- Verify transformation matrix: `"0 -1 1 1 0 0 0 0 1"`
- Restart display: `sudo systemctl restart localdisplay`

### Audio goes to HDMI instead of HiFiBerry
- Check service status: `systemctl status fix-audioout-cdsp`
- Check _audioout.conf: `grep slave.pcm /etc/alsa/conf.d/_audioout.conf`
- Should be: `slave.pcm "camilladsp"` (or `"plughw:0,0"` if CDSP disabled)
- Restart MPD: `sudo systemctl restart mpd`

### CamillaDSP not active
- Check service: `systemctl status camilladsp`
- Check config: `ls -l /usr/share/camilladsp/working_config.yml`
- Check database: `sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='camilladsp'"`
- Enable in moOde UI: Audio Config → CamillaDSP

## Access
**Web UI:** http://moode.local
**SSH:** `ssh andre@moode.local` (password: 0815)

## References
- **moOde Audio:** https://moodeaudio.org/
- **HiFiBerry AMP100:** https://www.hifiberry.com/shop/boards/hifiberry-amp100/
- **CamillaDSP:** https://github.com/HEnquist/camilladsp
- **Full Documentation:** `/backups/moode-10.0.2-working-2026-01-20/README.md`

## Version History
- **v1.0** (2026-01-21): Complete working configuration with display, touch, audio, CamillaDSP
- Based on moOde 10.0.2 (2025-12-18)
- Raspberry Pi 5, HiFiBerry AMP100, 1280x400 touchscreen

---

**✅ This configuration is tested and working. Share this repository with your friend!**

**GitHub Repository:** https://github.com/horstpeter0815/moodeaudio-ghettoblaster
