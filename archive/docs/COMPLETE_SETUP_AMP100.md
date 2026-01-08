# Komplettes Setup - Moode Audio Pi 5 + AMP100 + Display

## Hardware
- **Raspberry Pi 5**
- **HiFiBerry AMP100** (2x50W Stereo)
- **Waveshare 7.9" HDMI** (1280x400)

## Setup-Reihenfolge

### 1. Display-Fix (bereits erledigt)
```bash
./FIX_MOODE_DISPLAY_FINAL.sh
# Reboot
```

### 2. AMP100 Konfiguration
```bash
chmod +x CONFIGURE_AMP100.sh
./CONFIGURE_AMP100.sh
# Reboot
```

### 3. Hardware-Identifikation
```bash
chmod +x PHASE1_HARDWARE_WITH_AMP100.sh
./PHASE1_HARDWARE_WITH_AMP100.sh
```

### 4. ALSA-Konfiguration
```bash
chmod +x PHASE2_ALSA_AMP100.sh
./PHASE2_ALSA_AMP100.sh
```

### 5. MPD-Konfiguration (in Moode Audio UI)
- Audio Output: HiFiBerry AMP100
- Device: hw:0,0
- Format: 48kHz empfohlen

### 6. Audio-Test
```bash
# Test-Ton
speaker-test -c 2 -t wav

# Oder mit aplay
aplay -D hw:0,0 /usr/share/sounds/alsa/Front_Left.wav
```

## Verifikation

### Display
```bash
xrandr --output HDMI-A-2 --query | grep current
# Sollte zeigen: current 1280 x 400
```

### AMP100
```bash
# I2C
i2cdetect -y 1
# Sollte zeigen: 1a (WM8960)

# ALSA
aplay -l
# Sollte zeigen: card 0: sndrpihifiberry [snd_rpi_hifiberry_amp100]

# dmesg
dmesg | grep hifiberry
# Sollte AMP100-Info zeigen
```

### Audio-Pipeline
```bash
# MPD Status
systemctl status mpd

# ALSA Test
aplay -D hw:0,0 /usr/share/sounds/alsa/Front_Left.wav
```

## Konfigurations-Dateien

### /boot/firmware/config.txt
```ini
[all]
disable_fw_kms_setup=1
dtoverlay=hifiberry-amp100
dtparam=i2c=on

[pi5]
display_rotate=0
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_group=2
hdmi_mode=87
disable_overscan=1
framebuffer_width=1280
framebuffer_height=400
```

### /etc/asound.conf
```
pcm.!default {
    type hw
    card 0
    device 0
}

ctl.!default {
    type hw
    card 0
}
```

## Troubleshooting

### AMP100 wird nicht erkannt
1. Prüfe I2C: `i2cdetect -y 1`
2. Prüfe Overlay: `dmesg | grep hifiberry`
3. Prüfe Verbindung (GPIO-Pins)

### Kein Audio
1. Prüfe ALSA: `aplay -l`
2. Prüfe MPD: `systemctl status mpd`
3. Prüfe Lautstärke: `alsamixer`

### Display-Probleme
1. Prüfe config.txt
2. Prüfe xrandr: `xrandr --output HDMI-A-2 --query`
3. Prüfe xinitrc: `cat ~/.xinitrc`

---

**Status:** ✅ Setup-Scripts bereit

