# Audio Chain Quick Reference - Ghetto Blaster

## 🎯 Complete Audio Chain (PeppyMeter + CamillaDSP)

```
MPD → _audioout → camilladsp → peppy → _peppyout → plughw:0,0 → AMP100
```

## 📋 Critical Configuration

### Boot (`/boot/firmware/config.txt`)
```ini
dtoverlay=hifiberry-amp100,automute
dtparam=audio=off
dtparam=i2s=on
```

### Database (moOde)
```sql
cardnum = 0
i2sdevice = "HiFiBerry AMP100"
peppy_display = 1
peppy_display_type = "meter"
camilladsp = "bose_wave_filters.yml"  -- or your filter config
```

### ALSA Routing Logic

**`_audioout.conf` priority:**
1. CamillaDSP ON → `camilladsp`
2. PeppyMeter ON → `peppy`
3. Both OFF → `plughw:0,0`

**CamillaDSP playback:**
- PeppyMeter ON → `peppy`
- PeppyMeter OFF → `plughw:0,0`

**`_peppyout.conf`:**
- Always → `plughw:0,0`

### PeppyMeter Config (`/etc/peppymeter/config.txt`)
```ini
meter = blue
random.meter.interval = 0
meter.folder = 1280x400
```

## ✅ Quick Fixes

### Fix Audio Chain
```bash
sudo /usr/local/bin/fix-audio-chain.sh
```

### Set PeppyMeter Blue
```bash
sudo /usr/local/bin/set-peppymeter-blue.sh
```

### Validate Everything
```bash
sudo /usr/local/bin/validate-audio-chain.sh
```

## 🔍 Quick Checks

```bash
# AMP100 detected?
cat /proc/asound/cards | grep hifiberry

# ALSA routing correct?
cat /etc/alsa/conf.d/_audioout.conf
cat /etc/alsa/conf.d/_peppyout.conf

# Services running?
systemctl status mpd peppymeter camilladsp
```

## 📖 Full Documentation
See: `docs/COMPLETE_AUDIO_CHAIN_CONFIGURATION.md`
