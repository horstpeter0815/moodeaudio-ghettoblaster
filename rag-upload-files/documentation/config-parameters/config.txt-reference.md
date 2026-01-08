# config.txt Parameter-Referenz

**Vollständige Referenz aller config.txt Parameter für Ghetto Crew System**

---

## 📋 Übersicht

Die `config.txt` Datei befindet sich in `/boot/firmware/config.txt` (moOde) und wird beim Boot geladen.

**Wichtig:** Änderungen erfordern einen Neustart!

---

## 🖥️ Display & Video

### **Pi 5 Display Settings**

```ini
# Pi 5 KMS (Kernel Mode Setting)
dtoverlay=vc4-kms-v3d-pi5,noaudio
max_framebuffers=2
display_auto_detect=1
disable_fw_kms_setup=1
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `dtoverlay=vc4-kms-v3d-pi5` | `noaudio` | Pi 5 KMS Overlay (ohne Audio) |
| `max_framebuffers` | `2` | Maximale Framebuffer |
| `display_auto_detect` | `1` | Display automatisch erkennen |
| `disable_fw_kms_setup` | `1` | Firmware KMS Setup deaktivieren |

### **Custom Display Resolution (Ghetto Blaster)**

```ini
# 1280x400 Display für Ghetto Blaster
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `hdmi_group` | `2` | DMT (Display Monitor Timing) |
| `hdmi_mode` | `87` | Custom Mode |
| `hdmi_cvt` | `1280 400 60 6 0 0 0` | Width Height Refresh Aspect Ratio Flags |

**hdmi_cvt Format:**
```
hdmi_cvt=<width> <height> <framerate> <aspect> <margins> <interlace> <rb>
```

### **Display Rotation & Settings**

```ini
display_rotate=3
disable_overscan=1
hdmi_drive=2
hdmi_blanking=1
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `display_rotate` | `0-3` | 0=0°, 1=90°, 2=180°, 3=270° |
| `disable_overscan` | `1` | Overscan deaktivieren |
| `hdmi_drive` | `2` | HDMI Drive Mode (2=Normal) |
| `hdmi_blanking` | `1` | HDMI Blanking aktivieren |

### **HDMI Hotplug**

```ini
hdmi_force_hotplug=1
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
hdmi_force_edid_audio=1
hdmi_enable_4kp60=0
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `hdmi_force_hotplug` | `1` | HDMI als verbunden behandeln |
| `hdmi_force_hotplug:0` | `1` | HDMI Port 0 |
| `hdmi_force_hotplug:1` | `1` | HDMI Port 1 (Pi 4/5) |
| `hdmi_force_edid_audio` | `1` | EDID Audio erzwingen |
| `hdmi_enable_4kp60` | `0` | 4K@60Hz deaktivieren |

---

## 🔊 Audio

### **I2S & Audio**

```ini
dtparam=i2s=on
dtparam=audio=on
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `dtparam=i2s` | `on` | I2S Interface aktivieren |
| `dtparam=audio` | `on` | Audio aktivieren |

### **HiFiBerry AMP100 (Ghetto Blaster)**

```ini
dtoverlay=hifiberry-amp100,automute
force_eeprom_read=0
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `dtoverlay=hifiberry-amp100` | `automute` | HiFiBerry AMP100 HAT mit Auto-Mute |
| `force_eeprom_read` | `0` | EEPROM Read deaktivieren |

### **HiFiBerry BeoCreate (Ghetto Boom/Moob)**

```ini
dtoverlay=hifiberry-beocreate
```

### **HiFiBerry DAC+ ADC Pro (Ghetto Scratch)**

```ini
dtoverlay=hifiberry-dacplusadcpro
```

---

## 🔌 I2C & SPI

### **I2C**

```ini
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `dtparam=i2c_arm` | `on` | ARM I2C aktivieren |
| `dtparam=i2c_arm_baudrate` | `100000` | I2C Baudrate (100kHz) |

### **SPI**

```ini
dtparam=spi=on
```

---

## 🎛️ Touchscreen

### **FT6236 Touchscreen (Ghetto Blaster)**

```ini
# Wird von ft6236-delay.service geladen, NICHT in config.txt!
# dtoverlay=ft6236
```

**Wichtig:** Touchscreen wird von Systemd-Service geladen, nicht direkt in config.txt!

---

## ⚙️ System Settings

### **ARM & Boot**

```ini
arm_64bit=1
arm_boost=0
disable_splash=1
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `arm_64bit` | `1` | 64-bit Mode aktivieren |
| `arm_boost` | `0` | ARM Boost deaktivieren |
| `disable_splash` | `1` | Boot-Splash deaktivieren |

---

## 🚫 Deaktivierte Features

```ini
# Bluetooth (optional)
#dtoverlay=disable-bt

# WiFi (optional)
#dtoverlay=disable-wifi

# PCI Express (optional)
#dtparam=pciex1
#dtparam=pciex1_gen=3
```

---

## 📝 Beispiel: Vollständige config.txt

```ini
#########################################
# Ghettoblaster Custom Build
# This file is managed by moOde
#########################################

# Device filters
[cm4]
otg_mode=1

[pi4]
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
hdmi_enable_4kp60=0

[pi5]
# Pi 5 specific settings
dtoverlay=vc4-kms-v3d-pi5,noaudio
max_framebuffers=2
display_auto_detect=1
disable_fw_kms_setup=1
arm_64bit=1

[all]
# Display Settings
disable_overscan=1
display_rotate=3
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0

# System
arm_boost=0
disable_splash=1
hdmi_drive=2
hdmi_blanking=1
hdmi_force_edid_audio=1
hdmi_force_hotplug=1

# I2C/I2S
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2s=on
dtparam=audio=on

# Audio HAT
dtoverlay=hifiberry-amp100,automute
force_eeprom_read=0
```

---

## 🔗 Weitere Ressourcen

- **Raspberry Pi Dokumentation:** https://www.raspberrypi.com/documentation/computers/config_txt.html
- **Device Tree Overlays:** [dtoverlay-reference.md](dtoverlay-reference.md)
- **Hardware-Setup:** [../hardware-setup/](../hardware-setup/)

---

**Letzte Aktualisierung:** 2025-12-07

