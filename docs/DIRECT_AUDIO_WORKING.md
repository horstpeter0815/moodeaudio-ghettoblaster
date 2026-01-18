# Direct Audio Working Configuration - Ghetto Blaster
## Step-by-Step with Testing

**Date:** 2025-01-11  
**System:** Raspberry Pi 5 + HiFiBerry AMP100  
**Goal:** Direct audio (MPD → AMP100), NO PeppyMeter, NO CamillaDSP

---

## 🎯 Direct Audio Chain (Simplest)

```
MPD (Music Player Daemon)
  ↓ device "_audioout"
/etc/alsa/conf.d/_audioout.conf
  ↓ slave.pcm "plughw:0,0"
plughw:0,0 (HiFiBerry AMP100 - card 0, device 0)
  ↓
HiFiBerry AMP100 Hardware
  ↓
Speakers
```

---

## ✅ Step-by-Step Configuration with Testing

### Step 1: Boot Configuration (`/boot/firmware/config.txt`)

**Required Settings:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtparam=i2s=on
dtparam=audio=off
dtoverlay=hifiberry-amp100,automute
force_eeprom_read=0
```

**TEST:**
```bash
# Check boot config
grep -E "hifiberry-amp100|i2s=on|audio=off" /boot/firmware/config.txt

# Expected output:
# dtparam=i2s=on
# dtparam=audio=off
# dtoverlay=hifiberry-amp100,automute
```

**If test fails:** Fix config.txt, then REBOOT

---

### Step 2: Verify AMP100 Hardware Detection

**TEST:**
```bash
# Check if AMP100 is detected
cat /proc/asound/cards

# Expected output should show:
# 0 [sndrpihifiberry]: HiFiBerry_AMP100 - snd_rpi_hifiberry_amp100
#                      snd_rpi_hifiberry_amp100
```

**If test fails:**
- Check hardware connection
- Verify config.txt has `dtoverlay=hifiberry-amp100,automute`
- REBOOT after config.txt changes
- Check dmesg: `dmesg | grep -i hifiberry`

---

### Step 3: Check ALSA Device

**TEST:**
```bash
# List ALSA devices
aplay -l

# Expected output:
# card 0: sndrpihifiberry [snd_rpi_hifiberry_amp100], device 0: HiFiBerry AMP100 HiFiBerry AMP100 [HiFiBerry AMP100]
#   Subdevices: 1/1
#   Subdevice #0: subdevice #0
```

**TEST:**
```bash
# Test audio output directly
speaker-test -c 2 -t sine -f 1000 -D plughw:0,0

# Expected: You should hear test tone from speakers
# Press Ctrl+C to stop
```

**If test fails:**
- Check card number (might not be 0)
- Try: `speaker-test -c 2 -t sine -f 1000 -D plughw:1,0` (if card is 1)
- Check volume: `alsamixer -c 0` (press 'm' to unmute, arrow keys for volume)

---

### Step 4: moOde Database Configuration

**Required Settings:**
```sql
-- Audio device
cfg_system.cardnum = 0
cfg_system.i2sdevice = "HiFiBerry AMP100"

-- MPD device (CRITICAL: must be "_audioout", not card number)
cfg_mpd.device = "_audioout"

-- PeppyMeter OFF
cfg_system.peppy_display = 0

-- CamillaDSP OFF
cfg_system.camilladsp = "off"
```

**TEST:**
```bash
# Check database settings
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT param, value FROM cfg_system WHERE param IN ('cardnum', 'i2sdevice', 'peppy_display', 'camilladsp');"

sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT param, value FROM cfg_mpd WHERE param='device';"

# Expected output:
# cardnum|0
# i2sdevice|HiFiBerry AMP100
# peppy_display|0
# camilladsp|off
# device|_audioout
```

**If test fails:**
```bash
# Fix database
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='0' WHERE param='cardnum';"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='off' WHERE param='camilladsp';"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';"
```

---

### Step 5: ALSA Configuration (`/etc/alsa/conf.d/_audioout.conf`)

**Required Configuration:**
```
pcm._audioout {
    type copy
    slave.pcm "plughw:0,0"
}
```

**TEST:**
```bash
# Check _audioout.conf
cat /etc/alsa/conf.d/_audioout.conf

# Expected output:
# pcm._audioout {
#     type copy
#     slave.pcm "plughw:0,0"
# }
```

**If test fails:**
```bash
# Fix _audioout.conf
sudo tee /etc/alsa/conf.d/_audioout.conf > /dev/null << 'EOF'
pcm._audioout {
    type copy
    slave.pcm "plughw:0,0"
}
EOF
```

**TEST:**
```bash
# Test _audioout device
speaker-test -c 2 -t sine -f 1000 -D _audioout

# Expected: You should hear test tone from speakers
# Press Ctrl+C to stop
```

**If test fails:**
- Check card number in _audioout.conf (might need `plughw:1,0` if card is 1)
- Verify AMP100 is card 0: `cat /proc/asound/cards`

---

### Step 6: MPD Configuration

**TEST:**
```bash
# Check MPD status
systemctl status mpd

# Expected: active (running)
```

**TEST:**
```bash
# Check MPD config
grep "^audio_output" /etc/mpd.conf | head -5

# Expected: Should show audio_output device configuration
```

**TEST:**
```bash
# Restart MPD to pick up changes
sudo systemctl restart mpd
sleep 2
systemctl status mpd

# Expected: active (running) after restart
```

---

### Step 7: Final Audio Test

**TEST:**
```bash
# Play test file via MPD
mpc play
mpc status

# Expected: Should show playing status
# Check speakers for audio output
```

**TEST:**
```bash
# Check MPD is using correct device
mpc outputs

# Expected: Should show _audioout as active output
```

**If test fails:**
- Check MPD logs: `journalctl -u mpd -n 50`
- Verify _audioout.conf is correct
- Check volume: `mpc volume` (should be > 0)
- Try: `mpc volume 50` then `mpc play`

---

## 🔍 Complete Verification Checklist

Run all tests in order:

```bash
# 1. Boot config
grep -E "hifiberry-amp100|i2s=on|audio=off" /boot/firmware/config.txt

# 2. Hardware detection
cat /proc/asound/cards | grep -i hifiberry

# 3. ALSA device
aplay -l | grep -i hifiberry

# 4. Direct hardware test
speaker-test -c 2 -t sine -f 1000 -D plughw:0,0 &
sleep 3
pkill speaker-test

# 5. Database settings
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT param, value FROM cfg_system WHERE param IN ('cardnum', 'i2sdevice', 'peppy_display', 'camilladsp');"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT param, value FROM cfg_mpd WHERE param='device';"

# 6. ALSA config
cat /etc/alsa/conf.d/_audioout.conf

# 7. _audioout device test
speaker-test -c 2 -t sine -f 1000 -D _audioout &
sleep 3
pkill speaker-test

# 8. MPD status
systemctl status mpd --no-pager

# 9. MPD play test
mpc play
mpc status
mpc outputs
```

**All tests should pass before proceeding.**

---

## 🛠️ Quick Fix Script

If something fails, run this complete fix:

```bash
#!/bin/bash
# Complete direct audio fix

# 1. Find AMP100 card number
AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}')

if [ -z "$AMP100_CARD" ]; then
    echo "ERROR: AMP100 not detected!"
    exit 1
fi

echo "AMP100 detected as card $AMP100_CARD"

# 2. Update database
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='off' WHERE param='camilladsp';"
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';"

# 3. Fix _audioout.conf
sudo tee /etc/alsa/conf.d/_audioout.conf > /dev/null << EOF
pcm._audioout {
    type copy
    slave.pcm "plughw:$AMP100_CARD,0"
}
EOF

# 4. Restart MPD
sudo systemctl restart mpd

echo "✅ Audio fix complete"
echo "Test with: speaker-test -c 2 -t sine -f 1000 -D _audioout"
```

---

## ⚠️ Common Issues

### Issue: AMP100 Not Detected
**Symptom:** `cat /proc/asound/cards` shows no HiFiBerry
**Fix:**
1. Check `/boot/firmware/config.txt` has `dtoverlay=hifiberry-amp100,automute`
2. REBOOT (overlay changes require reboot)
3. Check hardware connection
4. Check dmesg: `dmesg | grep -i hifiberry`

### Issue: Wrong Card Number
**Symptom:** Card is 1 instead of 0
**Fix:** Update all references from `plughw:0,0` to `plughw:1,0`

### Issue: No Sound from Speakers
**Fix:**
1. Check volume: `alsamixer -c 0` (press 'm' to unmute)
2. Check MPD volume: `mpc volume 50`
3. Test direct: `speaker-test -c 2 -t sine -f 1000 -D plughw:0,0`

### Issue: MPD Not Playing
**Fix:**
1. Check MPD status: `systemctl status mpd`
2. Check MPD logs: `journalctl -u mpd -n 50`
3. Verify device: `mpc outputs` should show `_audioout`
4. Restart MPD: `sudo systemctl restart mpd`

---

## 📋 Configuration Summary

| Component | Setting | Value |
|-----------|---------|-------|
| Boot config | `dtoverlay` | `hifiberry-amp100,automute` |
| Boot config | `dtparam=i2s` | `on` |
| Boot config | `dtparam=audio` | `off` |
| Database | `cardnum` | `0` (or detected card number) |
| Database | `i2sdevice` | `HiFiBerry AMP100` |
| Database | `peppy_display` | `0` (OFF) |
| Database | `camilladsp` | `off` |
| Database | `mpd.device` | `_audioout` |
| ALSA | `_audioout.conf` | `slave.pcm "plughw:0,0"` |

---

**Status:** ✅ Testable Configuration  
**Next:** Test each step before proceeding  
**After working:** Can add PeppyMeter, then CamillaDSP
