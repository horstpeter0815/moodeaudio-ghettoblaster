# Pi 4 + HiFiBerry AMP100 - Funktionsfähige Konfiguration

**Datum:** 30. November 2025  
**Status:** ✅ **FUNKTIONIERT**  
**Hardware:** Raspberry Pi 4 Model B + HiFiBerry AMP100  
**OS:** Moode Audio 10.0.0

---

## 🎯 ZUSAMMENFASSUNG

**✅ AMP100 funktioniert perfekt auf Pi 4!**

- **ALSA Soundcard:** `card 2: sndrpihifiberry [snd_rpi_hifiberry_dacplus]`
- **I2C Hardware:** PCM5122 erkannt auf Bus 1, Adresse 0x4d
- **Overlay:** `dtoverlay=hifiberry-amp100` lädt korrekt
- **Sound-Node:** Wird durch Overlay erstellt
- **GPIO:** GPIO4 (MUTE), GPIO17 (RESET) konfiguriert

---

## 📋 KONFIGURATION

### `/boot/firmware/config.txt`

```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=on
force_eeprom_read=0
disable_fw_kms_setup=0
arm_64bit=1
arm_boost=1
disable_overscan=1

[all]
dtoverlay=hifiberry-amp100
```

**Wichtige Punkte:**
- ✅ `dtoverlay=vc4-kms-v3d-pi4,noaudio` - HDMI Audio deaktiviert
- ✅ `dtoverlay=hifiberry-amp100` - AMP100 Overlay aktiviert
- ✅ `force_eeprom_read=0` - EEPROM-Read deaktiviert (ohne `dtoverlay=`)
- ✅ `dtparam=i2c_arm=on` - I2C aktiviert
- ✅ `dtparam=i2s=on` - I2S aktiviert

### `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=75271919-02 rootfstype=ext4 fsck.repair=yes rootwait resize cfg80211.ieee80211_regdom=DE systemd.run=/boot/firstrun.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target video=HDMI-A-1:400x1280M@60,rotate=90 consoleblank=0
```

### Moode Audio Einstellungen

**i2sdevice:** `HiFiBerry AMP100`

**Setzen via SQL:**
```sql
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';
```

**Oder via moodeutl:**
```bash
moodeutl -w "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice'"
```

### MPD Konfiguration

**Standard (Moode verwaltet):**
```ini
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "software"
    dop "no"
    stop_dsd_silence "no"
    thesycon_dsd_workaround "no"
    close_on_pause "yes"
}
```

**Moode verwendet `_audioout`**, das automatisch auf die richtige ALSA Soundcard zeigt.

---

## 🔍 VERIFIZIERUNG

### 1. ALSA Soundcards prüfen

```bash
aplay -l
```

**Erwartete Ausgabe:**
```
**** List of PLAYBACK Hardware Devices ****
card 0: vc4hdmi0 [vc4-hdmi-0], device 0: MAI PCM i2s-hifi-0 [MAI PCM i2s-hifi-0]
card 1: vc4hdmi1 [vc4-hdmi-1], device 0: MAI PCM i2s-hifi-0 [MAI PCM i2s-hifi-0]
card 2: sndrpihifiberry [snd_rpi_hifiberry_dacplus], device 0: HiFiBerry DAC+ Pro HiFi pcm512x-hifi-0 [HiFiBerry DAC+ Pro HiFi pcm512x-hifi-0]
```

**✅ `card 2` ist die HiFiBerry AMP100!**

### 2. I2C Hardware prüfen

```bash
i2cdetect -y 1
```

**Erwartete Ausgabe:**
```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: -- -- -- -- -- -- -- -- -- -- -- -- UU -- -- 
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
```

**✅ `UU` bei 0x4d = PCM5122 DAC erkannt**

### 3. dmesg prüfen

```bash
dmesg | grep -i "hifiberry\|amp100\|pcm5122"
```

**Erwartete Ausgabe:**
```
snd-rpi-hifiberry-dacplus soc:sound: GPIO4 for HW-MUTE selected
snd-rpi-hifiberry-dacplus soc:sound: GPIO17 for HW-RESET selected
```

**✅ GPIO konfiguriert, Soundcard registriert**

### 4. Sound-Node prüfen

```bash
find /proc/device-tree -name "sound" -type d
```

**Erwartete Ausgabe:**
```
/proc/device-tree/soc/sound
```

**✅ Sound-Node vorhanden**

---

## 🎵 AUDIO-TEST

### Test-Ton abspielen

```bash
# Test mit aplay (falls Test-Sound vorhanden)
aplay /usr/share/sounds/alsa/Front_Left.wav

# Oder mit MPD
mpc play
mpc volume 50
```

### MPD Status prüfen

```bash
mpc status
```

**Erwartete Ausgabe:**
```
volume: 50%   repeat: off   random: off   single: off   consume: off
```

---

## 🔧 TROUBLESHOOTING

### Problem: Keine Soundcard

**Symptom:**
```bash
aplay -l
# --- no soundcards ---
```

**Lösung:**
1. Prüfe Overlay: `grep hifiberry /boot/firmware/config.txt`
2. Prüfe I2C: `i2cdetect -y 1`
3. Prüfe dmesg: `dmesg | grep -i hifiberry`
4. Reboot: `sudo reboot`

### Problem: Falsche Soundcard

**Symptom:**
MPD spielt über HDMI statt AMP100.

**Lösung:**
1. Prüfe Moode i2sdevice: `moodeutl -q "SELECT value FROM cfg_system WHERE param='i2sdevice'"`
2. Setze auf AMP100: `moodeutl -w "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice'"`
3. Restart MPD: `sudo systemctl restart mpd`

### Problem: force_eeprom_read falsch geschrieben

**Symptom:**
`dtoverlay=force_eeprom_read=0` in config.txt.

**Lösung:**
```bash
sudo sed -i 's/^dtoverlay=force_eeprom_read=0$/force_eeprom_read=0/' /boot/firmware/config.txt
```

**Korrekt:** `force_eeprom_read=0` (ohne `dtoverlay=`)

---

## 📝 FAZIT

**✅ Pi 4 + AMP100 = Perfekte Kombination!**

- Overlay funktioniert out-of-the-box
- Keine Workarounds nötig
- ALSA Soundcard wird korrekt registriert
- MPD kann direkt über AMP100 spielen

**Vergleich zu Pi 5:**
- Pi 4: ✅ Funktioniert
- Pi 5: ❌ Funktioniert nicht (Device Tree Inkompatibilität)

**Empfehlung:**
- **Für AMP100:** Pi 4 verwenden
- **Für andere Aufgaben:** Pi 5 verwenden

---

**Letzte Aktualisierung:** 30. November 2025  
**Status:** ✅ Funktionsfähig und dokumentiert

