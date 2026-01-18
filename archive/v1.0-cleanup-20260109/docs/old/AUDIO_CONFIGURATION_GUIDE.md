# Audio Configuration Guide - AMP100 vs Onboard Sound

**Date:** 2025-12-25  
**Status:** ✅ Configuration Guide

---

## 📋 I2S Device vs DT Overlay

### **DT Overlay (config.txt) - BESSER für Hardware**
- **Was:** `dtoverlay=hifiberry-amp100,automute` in config.txt
- **Wann:** Beim Boot, Hardware-Initialisierung
- **Warum besser:**
  - Aktiviert Hardware direkt beim Boot
  - Keine Software-Abhängigkeiten
  - Funktioniert auch ohne moOde
  - Auto-Mute kann direkt im Overlay gesetzt werden

### **I2S Device (moOde Database) - Für Software-Konfiguration**
- **Was:** `i2sdevice=HiFiBerry Amp(Amp+)` in moOde Database
- **Wann:** Nach Boot, Software-Konfiguration
- **Warum:**
  - Konfiguriert moOde/MPD für das Device
  - Setzt Mixer Controls korrekt
  - Aktiviert Device-spezifische Features

### **✅ EMPFEHLUNG: BEIDE verwenden!**
1. **DT Overlay:** Aktiviert Hardware beim Boot
2. **I2S Device:** Konfiguriert moOde/MPD nach Boot

---

## 🔧 Onboard Sound Deaktivieren

### **Warum deaktivieren?**
- Verhindert Konflikte zwischen HDMI Audio und AMP100
- AMP100 sollte einzige Audio-Quelle sein
- Reduziert System-Load

### **Wie deaktivieren:**

#### **1. In [pi5] Section:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
```

#### **2. In [all] Section:**
```ini
[all]
dtparam=audio=off
```

### **Vollständige Konfiguration:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtparam=audio=off
dtparam=i2s=on
dtoverlay=hifiberry-amp100,automute
force_eeprom_read=0
```

---

## ✅ Aktuelle Best Practice

### **config.txt:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio  # Onboard Sound AUS
hdmi_enable_4kp60=0

[all]
dtparam=audio=off                   # Onboard Sound AUS
dtparam=i2s=on                      # I2S AN (für AMP100)
dtoverlay=hifiberry-amp100,automute # AMP100 Hardware aktivieren
force_eeprom_read=0
```

### **moOde Database:**
```
i2sdevice: HiFiBerry Amp(Amp+)
mpdmixer: hardware
audioout: Local
```

---

## 🧪 Testing

### **Nach Reboot prüfen:**
```bash
# 1. ALSA Cards (sollte nur AMP100 zeigen, kein HDMI)
cat /proc/asound/cards

# Erwartet:
# 0 [sndrpihifiberry]: HifiberryDacp - snd_rpi_hifiberry_dacplus
# (KEINE vc4hdmi0 oder vc4hdmi1)

# 2. MPD Config
grep -A 5 "device.*_audioout" /etc/mpd.conf

# Sollte zeigen:
# mixer_device "hw:2"  (oder hw:0 wenn AMP100 Card 0 ist)
# mixer_control "Digital"
```

---

## 📝 Summary

**DT Overlay:** ✅ BESSER für Hardware-Initialisierung  
**I2S Device:** ✅ Für Software-Konfiguration  
**Beide:** ✅ Sollten verwendet werden

**Onboard Sound:** ✅ DEAKTIVIERT (noaudio + dtparam=audio=off)  
**AMP100:** ✅ AKTIVIERT (dtoverlay + I2S Device)

---

## 🔧 Script

**FIX_AUDIO_ONBOARD_OFF.sh** - Wendet alle Änderungen automatisch an

**Verwendung:**
```bash
sudo ./FIX_AUDIO_ONBOARD_OFF.sh [PI_IP]
# Default: 192.168.1.130
```

