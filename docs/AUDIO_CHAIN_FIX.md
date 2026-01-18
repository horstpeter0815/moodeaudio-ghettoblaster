# Audio Chain Fix for HiFiBerry AMP100

## Problem
Audio was not playing despite AMP100 being configured. The audio chain was broken at multiple points.

## Solution
Created a comprehensive fix script that ensures:
1. AMP100 is detected correctly
2. moOde database has correct card number
3. ALSA `_audioout.conf` points to AMP100
4. MPD is configured to use the correct device
5. Volume is unmuted and set to safe level
6. MPD is restarted to pick up changes

## Files Created

### 1. Fix Script
**Location:** `scripts/audio/fix-audio-chain.sh`
**Also installed to:** `/usr/local/bin/fix-audio-chain.sh` (on Pi)

**What it does:**
- Detects AMP100 card number
- Updates moOde database (`cardnum`, `i2sdevice`, MPD `device`)
- Fixes ALSA `_audioout.conf` to point to `plughw:0,0` (or correct card)
- Unmutes and sets safe volume (50%)
- Restarts MPD
- Verifies audio chain

**Usage:**
```bash
cd ~/moodeaudio-cursor && ./tools/fix.sh --audio
# or directly:
sudo /usr/local/bin/fix-audio-chain.sh
```

### 2. Systemd Service
**Location:** `moode-source/lib/systemd/system/fix-audio-chain.service`

**What it does:**
- Runs automatically on boot
- Runs after `sound.target` and `mpd.service`
- Ensures audio chain is fixed before MPD starts playing

### 3. Validation Script
**Location:** `scripts/audio/validate-audio-chain.sh`
**Also installed to:** `/usr/local/bin/validate-audio-chain.sh` (on Pi)

**What it does:**
- Checks AMP100 detection
- Verifies moOde database configuration
- Checks ALSA config files
- Verifies MPD status
- Checks volume/mute state
- Provides diagnostic information

**Usage:**
```bash
/usr/local/bin/validate-audio-chain.sh
```

## Integration

### Deployment Methods

#### Method 1: After Flashing moOde Image (Current Method)
When using a downloaded moOde image and applying fixes after flashing:

1. **Flash moOde image to SD card**
2. **Mount SD card** (bootfs and rootfs)
3. **Run install script:**
   ```bash
   cd ~/moodeaudio-cursor
   sudo ./INSTALL_FIXES_AFTER_FLASH.sh
   ```
   This will:
   - Copy `fix-audio-chain.sh` to `/usr/local/bin/` on the SD card
   - Copy `fix-audio-chain.service` to `/lib/systemd/system/` on the SD card
   - Enable the service to run on boot
   - Copy validation script to `/usr/local/bin/`

4. **Eject SD card and boot Pi**
5. **Audio chain will be fixed automatically on first boot**

#### Method 2: Custom Build
The fix script and service are automatically installed during custom image build via:
- `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh`
- Service is enabled automatically

#### Method 3: Manual Deployment (After Pi is Running)
If the Pi is already running and you need to fix audio:

**Via SSH:**
```bash
# Copy scripts to Pi
scp scripts/audio/fix-audio-chain.sh andre@192.168.10.2:/tmp/
scp scripts/audio/validate-audio-chain.sh andre@192.168.10.2:/tmp/
scp moode-source/lib/systemd/system/fix-audio-chain.service andre@192.168.10.2:/tmp/

# On Pi:
ssh andre@192.168.10.2
sudo mv /tmp/fix-audio-chain.sh /usr/local/bin/
sudo mv /tmp/validate-audio-chain.sh /usr/local/bin/
sudo mv /tmp/fix-audio-chain.service /lib/systemd/system/
sudo chmod +x /usr/local/bin/fix-audio-chain.sh
sudo chmod +x /usr/local/bin/validate-audio-chain.sh
sudo systemctl enable fix-audio-chain.service
sudo systemctl start fix-audio-chain.service
```

**Or use toolbox (if already deployed):**
```bash
cd ~/moodeaudio-cursor && ./tools/fix.sh --audio
```

## How It Works

### Audio Chain Flow
```
Music File
  ↓
MPD (Music Player Daemon)
  ↓
device "_audioout" (ALSA PCM device)
  ↓
/etc/alsa/conf.d/_audioout.conf
  ↓
slave.pcm "plughw:0,0" (or hw:0,0)
  ↓
HiFiBerry AMP100 (card 0, device 0)
  ↓
Speakers
```

### Key Components

1. **AMP100 Detection**
   - Checks `/proc/asound/cards` for `sndrpihifiberry` or `HiFiBerry AMP100`
   - Determines card number (usually 0)

2. **moOde Database**
   - Updates `cfg_system.cardnum` = AMP100 card number
   - Updates `cfg_system.i2sdevice` = "HiFiBerry AMP100"
   - Updates `cfg_mpd.device` = AMP100 card number

3. **ALSA Configuration**
   - Updates `/etc/alsa/conf.d/_audioout.conf`
   - Sets `slave.pcm` to `plughw:CARD,0` where CARD is AMP100 card number
   - Also fixes `_peppyout.conf` if PeppyMeter is enabled

4. **Volume Control**
   - Unmutes Master and PCM controls
   - Sets volume to 50% (safe level)
   - Sets MPD volume to 50%

5. **MPD Restart**
   - Restarts MPD service to pick up configuration changes
   - Waits for MPD to be ready before continuing

## Troubleshooting

### If audio still doesn't work:

1. **Check AMP100 detection:**
   ```bash
   cat /proc/asound/cards
   aplay -l
   ```

2. **Check boot configuration:**
   ```bash
   grep hifiberry-amp100 /boot/firmware/config.txt
   ```
   Should show: `dtoverlay=hifiberry-amp100,automute`

3. **Check ALSA config:**
   ```bash
   cat /etc/alsa/conf.d/_audioout.conf
   ```
   Should show: `slave.pcm "plughw:0,0"` (or correct card number)

4. **Check MPD status:**
   ```bash
   systemctl status mpd
   mpc outputs
   mpc status
   ```

5. **Check volume:**
   ```bash
   amixer -c 0 sget Master
   amixer -c 0 sget PCM
   mpc volume
   ```

6. **Test audio directly:**
   ```bash
   speaker-test -c 2 -t sine -f 1000 -D plughw:0,0
   ```

7. **Run validation:**
   ```bash
   /usr/local/bin/validate-audio-chain.sh
   ```

8. **Run fix again:**
   ```bash
   sudo /usr/local/bin/fix-audio-chain.sh
   ```

## Common Issues

### Issue: AMP100 not detected
**Solution:**
- Check `dtoverlay=hifiberry-amp100` in `/boot/firmware/config.txt`
- Reboot required after overlay changes
- Check hardware connection

### Issue: Wrong card number
**Solution:**
- Run fix script - it will detect correct card number
- Script updates database and ALSA config automatically

### Issue: MPD can't open device
**Solution:**
- Check `_audioout.conf` points to correct card
- Restart MPD: `sudo systemctl restart mpd`
- Check MPD logs: `journalctl -u mpd -n 50`

### Issue: Volume muted or too low
**Solution:**
- Fix script unmutes and sets volume to 50%
- Check: `amixer -c 0 sget Master`
- Unmute: `amixer -c 0 sset Master unmute`

## Related Files

- `moode-source/boot/firmware/config.txt.overwrite` - Boot config with AMP100 overlay
- `moode-source/etc/alsa/conf.d/_audioout.conf` - ALSA output config template
- `moode-source/www/inc/audio.php` - moOde audio configuration functions
- `moode-source/www/inc/mpd.php` - MPD configuration functions
- `scripts/audio/check-audio-chain.sh` - Original diagnostic script (still useful)

## Notes

- The fix script is idempotent - safe to run multiple times
- Service runs on boot to ensure audio chain is always correct
- Validation script provides quick diagnostics
- All scripts work from home directory: `cd ~/moodeaudio-cursor && ./tools/fix.sh --audio`
