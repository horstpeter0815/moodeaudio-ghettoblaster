# HiFiBerry AMP100 Configuration

**Date:** 2025-12-25  
**Status:** ✅ Konfiguriert, Reboot erforderlich

---

## ✅ Current Configuration

### config.txt Settings

```ini
[all]
# Ghettoblaster Audio - HiFiBerry AMP100
dtoverlay=hifiberry-amp100,automute
force_eeprom_read=0

dtparam=i2s=on
dtparam=i2c_arm=on
dtparam=audio=on
```

**Wichtig:**
- `dtoverlay=hifiberry-amp100,automute` - Aktiviert AMP100 mit Auto-Mute
- `force_eeprom_read=0` - Verhindert EEPROM-Konflikte
- `dtparam=i2s=on` - I2S aktiviert (erforderlich für AMP100)
- `dtparam=i2c_arm=on` - I2C aktiviert (für AMP100 Kommunikation)

---

## 📋 After Reboot

### Check AMP100 Detection

```bash
# ALSA Cards prüfen
cat /proc/asound/cards

# Sollte zeigen:
# 0 [sndrpihifiberry]: HiFiBerry AMP100 - snd_rpi_hifiberry_amp100
#    HiFiBerry AMP100

# ALSA Devices
aplay -l

# I2C Devices (AMP100 sollte auf I2C-Bus sein)
i2cdetect -y 1
```

### moOde Audio Settings

Nach Reboot in moOde Web-UI:
1. **System → Audio** → I2S Device auswählen
2. **HiFiBerry AMP100** sollte verfügbar sein
3. **Mixer:** Hardware (nicht Software)
4. **Output:** Local

### MPD Configuration

MPD sollte automatisch AMP100 erkennen wenn:
- ALSA Card vorhanden ist
- moOde Audio-Einstellungen korrekt sind

---

## ⚠️ Troubleshooting

### AMP100 nicht erkannt nach Reboot

1. **Prüfe Overlay:**
   ```bash
   ls -la /boot/firmware/overlays/hifiberry-amp100.dtbo
   ```

2. **Prüfe dtoverlay:**
   ```bash
   grep hifiberry-amp100 /boot/firmware/config.txt
   ```

3. **Prüfe I2S/I2C:**
   ```bash
   lsmod | grep i2s
   lsmod | grep i2c
   ```

4. **Prüfe Boot-Logs:**
   ```bash
   dmesg | grep -i hifiberry
   dmesg | grep -i amp100
   ```

### AMP100 erkannt aber kein Sound

1. **moOde Audio-Einstellungen prüfen:**
   - I2S Device: HiFiBerry AMP100
   - Mixer: Hardware
   - Output: Local

2. **MPD neu starten:**
   ```bash
   sudo systemctl restart mpd
   ```

3. **Test-Sound:**
   ```bash
   speaker-test -c 2 -t sine -f 1000
   ```

---

## 📝 Notes

- **automute:** Automatisches Muten wenn kein Signal
- **force_eeprom_read=0:** Verhindert Konflikte mit anderen HATs
- **I2S:** Erforderlich für digitale Audio-Übertragung
- **I2C:** Für AMP100 Kommunikation und Kontrolle

---

## 🔄 Reboot Required

**WICHTIG:** AMP100 wird erst nach Reboot aktiviert!

Nach Reboot:
1. Prüfe: `cat /proc/asound/cards`
2. Prüfe: `/usr/local/bin/check-amp100.sh`
3. Konfiguriere in moOde Web-UI

