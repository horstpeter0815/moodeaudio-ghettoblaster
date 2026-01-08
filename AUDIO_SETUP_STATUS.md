# Audio Setup Status

**Date:** 2025-12-25  
**Status:** ✅ AMP100 erkannt, ⚠️ moOde Konfiguration benötigt

---

## ✅ Current Status

### Hardware
- **AMP100:** ✅ Erkannt als ALSA Card 2 (`sndrpihifiberry`)
- **ALSA Devices:** ✅ Card 2, Device 0 verfügbar
- **Mixer Controls:** ✅ Digital, PCM, Auto Mute verfügbar
- **Volume:** ✅ Auf 0% (Maximum Volume Reduction beim Boot)

### moOde Configuration
- **I2S Device:** ✅ `HiFiBerry Amp(Amp+)` gesetzt
- **MPD:** ✅ Aktiv und läuft
- **⚠️ Problem:** MPD verwendet noch nicht AMP100 (verwendet noch `default:vc4hdmi0`)

---

## 🔧 Solution

### Option 1: Via moOde Web-UI (Recommended)

1. **Öffne moOde Web-UI:**
   ```
   http://192.168.1.138/
   ```

2. **Configure → Audio:**
   - **I2S Audio Device:** Wähle `HiFiBerry Amp(Amp+)`
   - **Mixer type:** Hardware
   - **Mixer name:** Digital (oder PCM)
   - Klicke **"Update"** oder **"Save"**

3. **MPD wird automatisch neu gestartet** und verwendet dann AMP100

### Option 2: Direct ALSA Test

```bash
# Volume erhöhen (z.B. auf 20%)
amixer -c 2 sset Digital 20%

# Test-Ton abspielen
speaker-test -c 2 -t sine -f 440 -l 1 -D hw:2,0
```

---

## 📋 Audio Configuration Details

### ALSA Card 2 (AMP100)
```
Card: sndrpihifiberry
Device: HiFiBerry DAC+ Pro HiFi pcm512x-hifi-0
Mixer: Digital (0-207)
```

### moOde Database
```
i2sdevice: HiFiBerry Amp(Amp+)
mpdmixer: hardware
audioout: Local
```

### MPD Config (sollte sein)
```
device "_audioout"
mixer_device "hw:2"
mixer_control "Digital"
```

**Aktuell (noch nicht aktualisiert):**
```
mixer_device "default:vc4hdmi0"
```

---

## ⚠️ Important Notes

1. **Volume ist auf 0%:** Wie gewünscht (Maximum Volume Reduction beim Boot)
2. **Volume erhöhen:** Via moOde Web-UI oder `amixer -c 2 sset Digital <value>%`
3. **MPD Update:** worker.php aktualisiert MPD Config automatisch nach Web-UI Änderung
4. **Auto-Mute:** ✅ Aktiviert (via dtoverlay + I2C Register)

---

## 🧪 Testing

### Test Audio Output:
```bash
# 1. Volume erhöhen
amixer -c 2 sset Digital 20%

# 2. Test-Ton
speaker-test -c 2 -t sine -f 440 -l 1 -D hw:2,0

# 3. MPD Test
mpc play
mpc volume 20
```

### Verify Configuration:
```bash
# ALSA Cards
cat /proc/asound/cards

# MPD Config
grep -A 5 "device.*_audioout" /etc/mpd.conf

# moOde Settings
moodeutl -q "SELECT param, value FROM cfg_system WHERE param='i2sdevice'"
```

---

## ✅ Next Steps

1. **Via Web-UI:** Configure → Audio → HiFiBerry Amp(Amp+) → Update
2. **Verify:** MPD sollte dann AMP100 verwenden
3. **Test:** Audio sollte funktionieren

**Status:** Hardware bereit, moOde Konfiguration via Web-UI erforderlich

