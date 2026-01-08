# Komplette System-Dokumentation

**Datum:** 1. Dezember 2025  
**Status:** ✅ Pi4 funktioniert vollständig | ⚠️ Pi5 Audio-Problem (Device Tree)

---

## 🎯 ZUSAMMENFASSUNG

### ✅ Raspberry Pi 4 (moodepi4)
- **Display:** ✅ 1280x400 Landscape funktioniert
- **PeppyMeter:** ✅ Funktioniert
- **Touchscreen:** ⚠️ Erkannt, aber reagiert nicht
- **Audio:** ✅ HiFiBerry AMP100 funktioniert perfekt

### ⚠️ Raspberry Pi 5 (ghettoblaster)
- **Display:** ✅ 1280x400 Landscape funktioniert
- **PeppyMeter:** ✅ Funktioniert (1280x400, Skin wechselbar)
- **Touchscreen:** ✅ Erkannt und konfiguriert
- **Audio:** ❌ HiFiBerry AMP100 funktioniert nicht (Device Tree Inkompatibilität)

---

## 📋 PI4 KONFIGURATION (FUNKTIONIERT)

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

### `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=... video=HDMI-A-1:400x1280M@60,rotate=90 consoleblank=0 ...
```

### Moode Audio Einstellungen

```sql
i2sdevice = 'HiFiBerry AMP100'
audioout = 'Local'
hdmi_scn_orient = 'portrait'
local_display = '1'
peppy_display = '0'
```

### Status

- ✅ ALSA Soundcard: `card 2: sndrpihifiberry [snd_rpi_hifiberry_dacplus]`
- ✅ I2C Hardware: PCM5122 erkannt auf Bus 1, Adresse 0x4d
- ✅ MPD funktioniert über AMP100

---

## 📋 PI5 KONFIGURATION (AUDIO PROBLEM)

### `/boot/firmware/config.txt`

```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
dtoverlay=hifiberry-amp100
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
force_eeprom_read=0
```

### `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=... video=HDMI-A-2:400x1280M@60,rotate=90 consoleblank=0 ...
```

### Moode Audio Einstellungen

```sql
i2sdevice = 'HiFiBerry AMP100'
audioout = 'Local'
hdmi_scn_orient = 'portrait'
local_display = '0'
peppy_display = '1'
peppy_display_type = 'meter'
```

### Status

- ❌ ALSA Soundcard: Keine Soundkarten
- ✅ I2C Hardware: PCM5122 erkannt auf Bus 13/14, Adresse 0x4d
- ❌ Problem: `deferred probe pending` - Overlay kann Sound-Node nicht erstellen
- ⚠️ Device Tree Inkompatibilität: Pi5 hat `/axi/...` statt `/soc/...`

---

## 🖥️ DISPLAY KONFIGURATION (BEIDE PIS)

### Waveshare 7.9" HDMI LCD (1280x400)

**Funktionsweise:**
1. Kernel startet Display im Portrait-Modus (400x1280)
2. X11 rotiert zu Landscape (1280x400) via `xrandr`
3. Chromium/PeppyMeter verwendet 1280x400

**Konfiguration:**
- `cmdline.txt`: `video=HDMI-A-X:400x1280M@60,rotate=90`
- `config.txt`: `hdmi_cvt 1280 400 60 6 0 0 0`
- `.xinitrc`: `xrandr --output HDMI-X --rotate left`

**Status:**
- ✅ Pi4: Funktioniert
- ✅ Pi5: Funktioniert

---

## 🎨 PEPPYMETER KONFIGURATION (PI5)

### `/etc/peppymeter/config.txt`

```ini
[current]
meter = tube
random.meter.interval = 20
base.folder =
meter.folder = 1280x400
screen.width = 1280
screen.height = 400
exit.on.touch = False
stop.display.on.touch = False
output.display = True
video.driver = x11
video.display = :0
```

### Verfügbare Skins

- `gold`
- `black-white`
- `white-red`
- `emerald`
- `orange`
- `tube` (aktuell)
- `red`
- `blue`

### Skin-Wechsel

```bash
sudo peppymeter-change-skin.sh <skin-name>
```

**Beispiele:**
```bash
sudo peppymeter-change-skin.sh gold
sudo peppymeter-change-skin.sh emerald
sudo peppymeter-change-skin.sh tube
```

### Status

- ✅ PeppyMeter läuft auf 1280x400
- ✅ Skins wechselbar
- ✅ Konfiguration persistent

---

## 👆 TOUCHSCREEN KONFIGURATION (PI5)

### Gerät

- **Name:** `WaveShare WaveShare`
- **ID:** `10` (kann variieren)
- **Typ:** USB-Touchscreen

### Konfiguration

**`.xinitrc`:**
```bash
# Touchscreen: X/Y vertauscht + beide invertiert
export DISPLAY=:0
sleep 3
xinput map-to-output 10 HDMI-1 2>/dev/null || true
xinput set-prop 10 "Coordinate Transformation Matrix" 0 -1 1 -1 0 1 0 0 1 2>/dev/null || true
```

**Matrix:** `0 -1 1 -1 0 1 0 0 1`
- X/Y vertauscht
- Beide Achsen invertiert

### Status

- ✅ Touchscreen erkannt
- ✅ Konfiguration persistent
- ⚠️ Feinabstimmung möglicherweise nötig

---

## 🔊 AUDIO PROBLEM PI5 - DETAILANALYSE

### Problem

**Symptom:**
- ❌ `aplay -l` zeigt keine Soundkarten
- ⚠️ `dmesg` zeigt: `deferred probe pending: (reason unknown)`
- ✅ Hardware erkannt: PCM5122 auf I2C Bus 13/14 (0x4d)
- ✅ ALSA Module geladen: `snd_soc_hifiberry_dacplus`, `snd_soc_pcm512x`

**Ursache:**
- Pi5 hat andere Device Tree Struktur (`/axi/...` statt `/soc/...`)
- Overlay sucht `<&sound>` und `<&i2s_clk_consumer>`, die auf Pi5 nicht existieren
- Overlay kann Sound-Node nicht erstellen

### Technische Details

**Pi4 Device Tree:**
```
/soc/
├── sound/          ✅ Existiert
├── i2s@.../        ✅ Mit Label
└── ...
```

**Pi5 Device Tree:**
```
/axi/
├── pcie@.../
│   └── rp1/
│       ├── i2c@.../  ✅ Existiert
│       └── i2s@.../  ❌ Kein Label
└── ...               ❌ Kein /soc/sound
```

**Overlay-Anforderungen:**
- `<&sound>` - existiert auf Pi4, nicht auf Pi5
- `<&i2s_clk_consumer>` - existiert auf Pi4, nicht auf Pi5
- `compatible = "brcm,bcm2835"` - sollte `"brcm,bcm2712"` für Pi5 sein

### Lösungsansätze

1. **Angepasstes Overlay erstellen** (komplex)
   - Sound-Node unter `/` erstellen
   - I2S Controller direkt referenzieren
   - I2C Bus korrekt mappen

2. **Auf HiFiBerry Update warten**
   - Offizielle Pi5-Unterstützung

3. **Pi4 für AMP100 verwenden** (aktuell)
   - Funktioniert perfekt
   - Keine Workarounds nötig

---

## 🔧 WICHTIGE SKRIPTE

### Skin-Wechsel

**Datei:** `/usr/local/bin/peppymeter-change-skin.sh`

**Verwendung:**
```bash
sudo peppymeter-change-skin.sh <skin-name>
```

**Funktion:**
- Prüft ob Skin existiert
- Ändert `/etc/peppymeter/config.txt`
- Löscht `/opt/peppymeter/config.txt` (hat Priorität)
- Startet PeppyMeter neu

---

## 📝 KONFIGURATIONS-DATEIEN

### Pi4

- `/boot/firmware/config.txt` - Hardware-Konfiguration
- `/boot/firmware/cmdline.txt` - Kernel-Parameter
- `/home/andre/.xinitrc` - X11 Startup
- `/var/local/www/db/moode-sqlite3.db` - Moode Einstellungen

### Pi5

- `/boot/firmware/config.txt` - Hardware-Konfiguration
- `/boot/firmware/cmdline.txt` - Kernel-Parameter
- `/home/andre/.xinitrc` - X11 Startup
- `/etc/peppymeter/config.txt` - PeppyMeter Konfiguration
- `/var/local/www/db/moode-sqlite3.db` - Moode Einstellungen

---

## ✅ TEST-CHECKLISTE

### Pi4

- [x] Display: 1280x400 Landscape
- [x] Audio: AMP100 funktioniert
- [x] MPD: Spielt über AMP100
- [ ] Touchscreen: Reagiert nicht (Hardware-Problem?)

### Pi5

- [x] Display: 1280x400 Landscape
- [x] PeppyMeter: Läuft auf 1280x400
- [x] Skins: Wechselbar
- [x] Touchscreen: Erkannt und konfiguriert
- [ ] Audio: AMP100 funktioniert nicht (Device Tree Problem)

---

## 🚀 NÄCHSTE SCHRITTE

1. **Pi5 Audio:**
   - Angepasstes Overlay erstellen/testen
   - Oder auf HiFiBerry Update warten

2. **Pi4 Touchscreen:**
   - Hardware-Verbindung prüfen
   - Alternative Treiber testen

3. **Dokumentation:**
   - ✅ Vollständig dokumentiert
   - ✅ Alle Konfigurationen gespeichert

---

**Letzte Aktualisierung:** 1. Dezember 2025  
**Status:** Dokumentation vollständig, Pi4 funktioniert, Pi5 Audio-Problem dokumentiert

