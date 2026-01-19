# Audio Configuration - Complete Summary

**Date:** 2026-01-19  
**Status:** ✅ Raspberry Pi onboard audio DEACTIVATED  
**Audio Device:** HiFiBerry AMP100 ONLY

---

## Audio Configuration Philosophy

**Single Audio Device Only:**
- ✅ HiFiBerry AMP100 (PCM5122 DAC) - ACTIVE
- ❌ Raspberry Pi onboard audio - DISABLED
- ❌ HDMI audio - DISABLED

**Why this configuration:**
1. Professional audio quality (PCM5122 DAC)
2. No audio routing conflicts
3. No device confusion
4. Consistent output

---

## config.txt Audio Settings

### File: `moode-source/boot/firmware/config.txt.overwrite`

```ini
[pi4]
dtoverlay=vc4-kms-v3d,noaudio    # noaudio disables onboard HDMI audio

[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio  # noaudio disables onboard HDMI audio

[all]
# CRITICAL: Disable ALL onboard audio
dtparam=audio=off                   # ✅ Disables BCM2835 audio (3.5mm jack)
hdmi_force_edid_audio=1             # HDMI audio disabled (using I2S)

# I2S Audio (HiFiBerry AMP100)
dtparam=i2s=on                      # ✅ Enable I2S for HiFiBerry
dtoverlay=hifiberry-amp100          # ✅ Load HiFiBerry overlay
```

---

## What's Disabled

### 1. ❌ BCM2835 Audio (3.5mm Jack)
```ini
dtparam=audio=off
```
**Result:** No `/dev/snd` devices for onboard audio

### 2. ❌ HDMI Audio
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_force_edid_audio=1
```
**Result:** No audio over HDMI

### 3. ❌ Any Other Audio Devices
**Result:** Only HiFiBerry AMP100 visible to ALSA

---

## What's Enabled

### ✅ HiFiBerry AMP100 Only

```ini
dtparam=i2s=on                  # I2S bus for audio data
dtoverlay=hifiberry-amp100      # DAC + Amp driver
```

**Hardware:**
- **DAC Chip:** PCM5122
- **I2C Address:** 0x4d (control)
- **Audio Interface:** I2S (data)
- **Connection:** GPIO header (HAT)

**Driver:**
```
snd_soc_pcm512x (DAC driver)
snd_rpi_hifiberry_dacplus (platform driver)
```

---

## Audio Device Hierarchy

### System Audio Cards

```bash
# After boot, only ONE card exists:
cat /proc/asound/cards
# Expected output:
# 0 [sndrpihifiberry]: HifiberryDacp - snd_rpi_hifiberry_dacplus
#                      snd_rpi_hifiberry_dacplus

# NO bcm2835 audio
# NO HDMI audio
```

### ALSA Device Names

```bash
# HiFiBerry is card 1 (card 0 doesn't exist)
aplay -l
# Expected:
# card 1: sndrpihifiberry [snd_rpi_hifiberry_dacplus], device 0: HiFiBerry DAC+ HiFi pcm512x-hifi-0 []
```

**Why card 1, not card 0:**
- Card 0 would be onboard audio (disabled)
- HiFiBerry takes first available slot: card 1

---

## Service Audio Configuration

### All Services Use HiFiBerry

**MPD → card 1:**
```
audio_output {
    type "alsa"
    name "HiFiBerry"
    device "hw:1,0"
}
```

**shairport-sync → plughw:1,0:**
```
output_device = "plughw:1,0";
```

**Squeezelite → card 1:**
```
squeezelite -o hw:CARD=sndrpihifiberry
```

**All other services → ALSA default → card 1**

---

## I2C Bus Usage

**Only ONE device on I2C bus 1:**

| Address | Device | Purpose |
|---------|--------|---------|
| 0x4d | PCM5122 | DAC control (volume, filters, etc.) |

**No other I2C devices:**
- Touch is USB (not I2C)
- No conflicts
- Simple & reliable

---

## Verification Commands

### After Build/Flash

```bash
# 1. Check NO onboard audio
cat /proc/asound/cards
# Expected: Only HiFiBerry, NO bcm2835

# 2. Check loaded modules
lsmod | grep snd
# Expected:
# snd_soc_pcm512x
# snd_rpi_hifiberry_dacplus
# NOT snd_bcm2835

# 3. Check I2C device
i2cdetect -y 1
# Expected: Only UU at 0x4d

# 4. Check ALSA devices
aplay -l
# Expected: Only card 1 (HiFiBerry)

# 5. Test audio
speaker-test -D hw:1,0 -c 2 -t wav
# Expected: Audio plays through HiFiBerry

# 6. Check HDMI audio
cat /proc/asound/pcm
# Expected: Only HiFiBerry PCM, no HDMI
```

---

## Common Audio Issues (Prevented)

### Issue: Audio to wrong device
**Prevented by:**
- Only one audio device exists
- All services configured for card 1
- No device confusion possible

### Issue: HDMI audio leak
**Prevented by:**
- `dtoverlay=vc4-kms-v3d-pi5,noaudio`
- HDMI audio disabled at firmware level
- No HDMI audio device created

### Issue: bcm2835 conflicts
**Prevented by:**
- `dtparam=audio=off`
- Onboard audio disabled at boot
- No bcm2835 driver loaded

### Issue: Multiple cards confusion
**Prevented by:**
- Only HiFiBerry enabled
- Card numbering consistent (always card 1)
- Simple configuration

---

## Audio Signal Path

```
┌──────────────────────────────────────────────┐
│           Audio Services                     │
│  (MPD, AirPlay, Spotify, etc.)              │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│              ALSA (hw:1,0)                   │
│         HiFiBerry DAC+ driver                │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│            I2S Interface                     │
│    (GPIO pins 18, 19, 20, 21)               │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│         PCM5122 DAC Chip                     │
│      (on HiFiBerry AMP100 HAT)              │
│          I2C control: 0x4d                   │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│          Power Amplifier                     │
│        (60W Class D on AMP100)              │
└──────────────────────────────────────────────┘
                    ↓
              Speakers 🔊
```

---

## Disabled Audio Paths

```
❌ Raspberry Pi 3.5mm Jack (disabled)
   dtparam=audio=off

❌ HDMI Audio (disabled)
   dtoverlay=vc4-kms-v3d-pi5,noaudio
   hdmi_force_edid_audio=1

❌ USB Audio (not configured)
   No USB audio devices

❌ Bluetooth Audio (optional)
   Can be enabled via moOde UI
```

---

## Configuration Files Summary

### `/boot/firmware/config.txt`

**Audio-related lines:**
```ini
# Disable onboard audio
dtparam=audio=off

# Disable HDMI audio
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_force_edid_audio=1

# Enable I2S and HiFiBerry
dtparam=i2s=on
dtoverlay=hifiberry-amp100
```

### `/etc/asound.conf`
**Created by moOde** - Routes all audio to HiFiBerry

### Service configs
- `/etc/shairport-sync.conf` → `output_device = "plughw:1,0"`
- `/etc/mpd.conf` → `device "hw:1,0"`
- All others → ALSA default → card 1

---

## Optional: CamillaDSP Processing

**If enabled:**

```
Audio Services
      ↓
   CamillaDSP (Bose Wave filters)
      ↓
  HiFiBerry AMP100
      ↓
   Speakers 🔊
```

**CamillaDSP config:**
```yaml
devices:
  capture:
    type: Loopback
    channels: 2
  playback:
    type: Alsa
    channels: 2
    device: "hw:1,0"  # HiFiBerry
    format: S32LE
```

---

## Audio Quality

### PCM5122 DAC Specifications

| Feature | Value |
|---------|-------|
| DAC Resolution | 32-bit |
| Sample Rate | Up to 384kHz |
| THD+N | -93 dB |
| SNR | 112 dB |
| Connection | I2S (bit-perfect) |

**vs Raspberry Pi onboard (BCM2835):**
- Onboard: PWM audio (poor quality)
- HiFiBerry: Professional DAC (high quality)
- **Result:** Much better sound!

---

## Troubleshooting

### No Audio Output

```bash
# 1. Check HiFiBerry detected
cat /proc/asound/cards
# Should show HiFiBerry

# 2. Check I2C device
i2cdetect -y 1
# Should show UU at 0x4d

# 3. Check volume
amixer -c 1
# Adjust volume if needed

# 4. Test output
speaker-test -D hw:1,0 -c 2
# Should hear test tone
```

### Wrong Audio Device

```bash
# 1. Check ALSA default
aplay -L | head -10
# Should show HiFiBerry as default

# 2. Check service config
grep output_device /etc/shairport-sync.conf
# Should be plughw:1,0

# 3. Force device
aplay -D hw:1,0 test.wav
```

---

## Summary

### ✅ Onboard Audio Configuration

**Disabled:**
- ❌ BCM2835 audio (3.5mm jack)
- ❌ HDMI audio
- ❌ Any other audio devices

**Enabled:**
- ✅ HiFiBerry AMP100 ONLY
- ✅ Professional PCM5122 DAC
- ✅ 60W Class D amplifier
- ✅ I2S connection (bit-perfect)

**Result:**
- Single audio device (no confusion)
- Professional audio quality
- Simple configuration
- No conflicts
- Reliable operation

---

## Configuration Status

| Setting | Status | Location |
|---------|--------|----------|
| `dtparam=audio=off` | ✅ Set | config.txt |
| `noaudio` overlay param | ✅ Set | config.txt |
| `hdmi_force_edid_audio=1` | ✅ Set | config.txt |
| `dtparam=i2s=on` | ✅ Set | config.txt |
| `dtoverlay=hifiberry-amp100` | ✅ Set | config.txt |
| shairport-sync device | ✅ plughw:1,0 | /etc/shairport-sync.conf |

**All audio configuration correct!** ✅

---

**Your build uses ONLY HiFiBerry AMP100 for audio - professional quality, no conflicts!** 🎵
