# moOde Settings - Konfigurationsparameter

**moOde-spezifische Einstellungen und Parameter für Ghetto Crew System**

---

## 📋 Übersicht

moOde verwendet verschiedene Konfigurationsdateien und Datenbank-Einträge für Einstellungen.

**Wichtigste Locations:**
- `/var/www/html/` - Web-UI
- `/var/lib/mpd/` - MPD Config
- `/etc/camilladsp/` - CamillaDSP Config
- SQLite DB: `/var/local/www/db/moode-sqlite3.db`

---

## 🎛️ Audio Settings

### **Audio Output**

| Setting | Wert | Beschreibung |
|---------|------|--------------|
| `audio_output_format` | `S32_LE` | 32-bit Audio Format |
| `audio_output_rate` | `192000` | 192kHz Sample Rate |
| `audio_output_channels` | `2` | Stereo |
| `audio_device` | `hifiberry-amp100` | HiFiBerry AMP100 |

### **MPD Configuration**

```bash
# MPD Config Location
/etc/mpd.conf

# Wichtige Parameter:
audio_output {
    type "alsa"
    name "HiFiBerry AMP100"
    device "hw:0,0"
    mixer_type "hardware"
    mixer_device "hw:0"
    mixer_control "Digital"
}
```

---

## 🎚️ Equalizer Settings

### **Flat EQ Preset**

**Location:** `/var/www/html/command/ghettoblaster-flat-eq.json`

```json
{
  "name": "Ghetto Crew Flat EQ",
  "bands": [
    { "freq": 20, "gain": 0.0 },
    { "freq": 100, "gain": 0.0 },
    { "freq": 130, "gain": -5.0 },
    { "freq": 225, "gain": -5.0 },
    { "freq": 250, "gain": -5.0 },
    { "freq": 500, "gain": 0.0 },
    { "freq": 1000, "gain": 0.0 },
    { "freq": 3000, "gain": 0.0 },
    { "freq": 6000, "gain": 7.0 },
    { "freq": 10000, "gain": 0.0 },
    { "freq": 20000, "gain": 0.0 }
  ]
}
```

**Aktivierung:**
- Web-UI: Audio Settings → "Flat EQ (Factory Settings)" Checkbox
- API: `POST /command/ghettoblaster-flat-eq.php?cmd=toggle&enabled=1`

---

## 🎨 Room Correction

### **CamillaDSP Configuration**

**Location:** `/etc/camilladsp/config.yml`

**Quick Convolution:**
```yaml
filters:
  quick_conv:
    type: Convolution
    parameters:
      type: Wav
      channels: 2
      filename: /var/lib/camilladsp/convolution/filter.wav
```

**Filter Location:**
- `/var/lib/camilladsp/convolution/` - FIR Filter (WAV)
- `/var/lib/camilladsp/measurements/` - Messungen

### **Room Correction Wizard**

**API Endpoint:** `/command/room-correction-wizard.php`

**Commands:**
- `start_wizard` - Wizard starten
- `upload_measurement` - Messung hochladen
- `generate_filter` - Filter generieren
- `apply_filter` - Filter anwenden
- `ab_test` - A/B Test

---

## 🖥️ Display Settings

### **PeppyMeter**

**Location:** `/opt/peppymeter/`

**Config:**
```ini
[display]
width = 1280
height = 400
rotation = 180
```

**Touch Gestures:**
- **Double-Tap:** Wechsel zwischen Power Meter / Temp / Stream Info
- **Single-Tap:** PeppyMeter Ein/Aus

**Service:** `peppymeter-extended-displays.service`

---

## 🔧 System Settings

### **I2C Configuration**

**Location:** `/boot/firmware/config.txt`

```ini
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
```

**Services:**
- `i2c-monitor.service` - I2C Monitoring
- `i2c-stabilize.service` - I2C Stabilisierung

### **Audio Optimization**

**Service:** `audio-optimize.service`

**Settings:**
- CPU Governor: `performance`
- IRQ Affinity: Audio-Cores
- Real-time Priority: MPD

---

## 📊 Database Settings

### **SQLite Database**

**Location:** `/var/local/www/db/moode-sqlite3.db`

**Wichtige Tabellen:**
- `cfg_system` - System-Einstellungen
- `cfg_mpd` - MPD-Einstellungen
- `cfg_audio` - Audio-Einstellungen

**Ghetto Crew Settings:**
```sql
-- Flat EQ Status
SELECT * FROM cfg_system WHERE param = 'ghettoblaster_flat_eq';

-- Room Correction
SELECT * FROM cfg_system WHERE param LIKE 'room_correction%';
```

---

## 🌐 Web-UI Settings

### **Session Settings**

**Location:** PHP Session

**Settings:**
- `ghettoblaster_flat_eq` - Flat EQ Status (0/1)
- `room_correction_enabled` - Room Correction Status (0/1)
- `room_correction_preset` - Aktueller Preset

---

## 🔐 Security Settings

### **File Permissions**

```bash
# Web-UI
/var/www/html/ - www-data:www-data (755)

# Config Files
/etc/camilladsp/ - root:root (644)

# Measurements
/var/lib/camilladsp/measurements/ - www-data:www-data (755)
```

---

## 📝 Custom Settings

### **Ghetto Crew Specific**

**Flat EQ:**
- Config: `/var/www/html/command/ghettoblaster-flat-eq.json`
- Handler: `/var/www/html/command/ghettoblaster-flat-eq.php`
- DB: `cfg_system.ghettoblaster_flat_eq`

**Room Correction:**
- Wizard: `/var/www/html/templates/snd-config.html`
- Handler: `/var/www/html/command/room-correction-wizard.php`
- Filters: `/var/lib/camilladsp/convolution/`

**PeppyMeter Extended:**
- Script: `/opt/peppymeter/extended-displays.py`
- Service: `peppymeter-extended-displays.service`

---

## 🔗 Weitere Ressourcen

- **config.txt:** [config.txt-reference.md](config.txt-reference.md)
- **dtoverlay:** [dtoverlay-reference.md](dtoverlay-reference.md)
- **Commands:** [../quick-reference/commands.md](../quick-reference/commands.md)

---

**Letzte Aktualisierung:** 2025-12-07

