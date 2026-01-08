# HiFiBerry AMP100 Konfiguration

## Hardware
- **HiFiBerry AMP100** - 2x50W Stereo-Verstärker
- **Raspberry Pi 5** - Moode Audio
- **Waveshare 7.9" HDMI** - Display (1280x400)

## Konfiguration

### 1. Device Tree Overlay

In `/boot/firmware/config.txt`:
```ini
[all]
dtoverlay=hifiberry-amp100
```

**Wichtig:**
- AMP100 verwendet I2S für Audio
- Benötigt I2C für Konfiguration
- GPIO-Pins werden automatisch konfiguriert

### 2. ALSA Konfiguration

#### `/etc/asound.conf` (systemweit):
```
pcm.!default {
    type hw
    card 0
}

ctl.!default {
    type hw
    card 0
}
```

#### Prüfe ALSA-Gerät:
```bash
aplay -l
# Sollte zeigen: card 0: sndrpihifiberry [snd_rpi_hifiberry_amp100], device 0: HiFiBerry AMP100 HiFi wm8960-hifi-0 []
```

### 3. MPD Konfiguration

In Moode Audio:
- Audio Output: `HiFiBerry AMP100`
- Device: `hw:0,0`
- Format: 16/32/44.1/48/88.2/96/176.4/192 kHz

### 4. I2C Prüfung

```bash
# Prüfe I2C-Geräte
i2cdetect -y 1

# AMP100 sollte auf 0x1a erscheinen (WM8960 Codec)
```

### 5. GPIO/Device Tree Prüfung

```bash
# Prüfe geladene Overlays
dmesg | grep -i "hifiberry\|amp100\|wm8960"

# Prüfe Device Tree
ls /proc/device-tree/soc/sound/
```

## Troubleshooting

### AMP100 wird nicht erkannt
1. Prüfe I2C-Verbindung: `i2cdetect -y 1`
2. Prüfe Overlay: `dmesg | grep hifiberry`
3. Prüfe ALSA: `aplay -l`

### Kein Audio-Output
1. Prüfe Lautstärke: `alsamixer`
2. Prüfe MPD-Status: `systemctl status mpd`
3. Prüfe ALSA-Test: `speaker-test -c 2 -t wav`

### Verzerrungen
1. Prüfe Sample-Rate (sollte 48kHz oder 96kHz sein)
2. Prüfe Lautstärke (nicht zu hoch)
3. Prüfe Verstärker-Temperatur

## Nächste Schritte

1. Hardware-Identifikation mit AMP100
2. ALSA-Konfiguration setzen
3. MPD für AMP100 konfigurieren
4. Audio-Test durchführen

---

**Status:** 🔄 Konfiguration vorbereitet

