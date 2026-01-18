# AMP100 Auto-Mute und Volume-Zero Konfiguration

**Date:** 2025-12-25  
**Status:** ✅ Konfiguriert für Standard Moode Audio Image

---

## ✅ Konfiguration

### 1. Auto-Mute (via dtoverlay + I2C Register)

**config.txt:**
```ini
dtoverlay=hifiberry-amp100,automute
force_eeprom_read=0
```

**Nach Boot (via I2C Register):**
- Script: `/usr/local/bin/amp100-automute.sh`
- Service: `amp100-automute.service`
- Setzt PCM5122 Auto-Mute Register (0x3B) auf 0x11
- Komplementiert das dtoverlay `automute` Parameter

### 2. Volume Zero (Maximum Volume Reduction)

**Nach Boot:**
- Script: `/usr/local/bin/amp100-volume-zero.sh`
- Service: `amp100-volume-zero.service`
- Setzt Volume auf 0% beim Boot
- Prüft Mixer Controls: PCM, Digital, Master
- Setzt auch MPD Volume auf 0

---

## 📋 Service Abhängigkeiten

```
sound.target
  └─ amp100-automute.service (Auto-Mute Register setzen)
      └─ amp100-volume-zero.service (Volume auf 0 setzen)
          └─ mpd.service (MPD startet danach)
```

---

## 🔧 Manuelle Ausführung

### Auto-Mute setzen:
```bash
sudo /usr/local/bin/amp100-automute.sh
```

### Volume auf 0 setzen:
```bash
sudo /usr/local/bin/amp100-volume-zero.sh
```

### Service Status prüfen:
```bash
systemctl status amp100-automute.service
systemctl status amp100-volume-zero.service
```

---

## 📝 Technische Details

### PCM5122 Auto-Mute Register
- **I2C Address:** 0x4d
- **Register:** 0x3B (Page 0, Register 59)
- **Value:** 0x11 (Auto-Mute enabled für beide Kanäle)
- **Command:** `i2cset -y 1 0x4d 0x3b 0x11`

### Volume Zero
- **Mixer Controls:** PCM, Digital, Master
- **ALSA:** `amixer -c <card> sset <control> 0% unmute`
- **MPD:** `mpc volume 0`

---

## ⚠️ Wichtig

**Reboot erforderlich:**
- AMP100 wird erst nach Reboot aktiviert
- Auto-Mute und Volume-Zero werden dann automatisch gesetzt

**Nach Reboot prüfen:**
```bash
# Auto-Mute Register prüfen
i2cget -y 1 0x4d 0x3b

# Volume prüfen
amixer -c 0 get PCM
mpc volume
```

---

## 🔄 Integration in Custom Build

Diese Scripts und Services sind bereits in `moode-source/` integriert:
- `moode-source/usr/local/bin/amp100-automute.sh`
- `moode-source/usr/local/bin/amp100-volume-zero.sh`
- `moode-source/lib/systemd/system/amp100-automute.service`
- `moode-source/lib/systemd/system/amp100-volume-zero.service`

Sie werden automatisch in das Custom Image integriert.

