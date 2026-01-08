# Device Tree Overlay (DTO) Referenz

**Übersicht aller verwendeten Device Tree Overlays für Ghetto Crew System**

---

## 📋 Was sind Device Tree Overlays?

Device Tree Overlays (DTO) aktivieren Hardware-Features auf dem Raspberry Pi ohne Kernel-Modifikationen.

**Format:**
```ini
dtoverlay=<overlay-name>,<param1>=<value1>,<param2>=<value2>
```

---

## 🔊 Audio HATs

### **HiFiBerry AMP100** (Ghetto Blaster - Pi 5)

```ini
dtoverlay=hifiberry-amp100,automute
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `automute` | - | Auto-Mute bei Signalverlust |

**Details:**
- 2x50W Class D Amplifier
- I2S Input
- Auto-Mute Feature

---

### **HiFiBerry BeoCreate** (Ghetto Boom/Moob - Pi 4)

```ini
dtoverlay=hifiberry-beocreate
```

**Details:**
- Multi-Channel Audio
- 8x Bose 901 Treiber
- Fostex Mid/Tweeter Support

---

### **HiFiBerry DAC+ ADC Pro** (Ghetto Scratch - Pi Zero 2W)

```ini
dtoverlay=hifiberry-dacplusadcpro
```

**Details:**
- DAC für Audio-Output
- ADC für Phono-Input
- MM/MC Phono Preamp Support

---

## 🖥️ Display & Video

### **Pi 5 KMS (Kernel Mode Setting)**

```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `noaudio` | - | Audio über HDMI deaktivieren |

**Details:**
- Moderne Display-Pipeline für Pi 5
- Hardware-Beschleunigung
- `noaudio` = Audio über HAT, nicht HDMI

---

## 🎛️ Touchscreen

### **FT6236 Touchscreen Controller**

```ini
# Wird von Systemd-Service geladen!
# dtoverlay=ft6236
```

**Wichtig:** Wird NICHT direkt in config.txt geladen, sondern von `ft6236-delay.service`!

**Service:** `/etc/systemd/system/ft6236-delay.service`

---

## 🔌 I2C & SPI

### **I2C**

```ini
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
```

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `i2c_arm` | `on` | ARM I2C aktivieren |
| `i2c_arm_baudrate` | `100000` | Baudrate (100kHz) |

### **SPI**

```ini
dtparam=spi=on
```

---

## 🚫 Deaktivierte Features

### **Bluetooth**

```ini
#dtoverlay=disable-bt
```

### **WiFi**

```ini
#dtoverlay=disable-wifi
```

---

## 📝 Overlay-Kombinationen

### **Ghetto Blaster (Pi 5)**

```ini
# Display
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Audio
dtoverlay=hifiberry-amp100,automute

# I2C (für Touchscreen)
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
```

### **Ghetto Boom/Moob (Pi 4)**

```ini
# Audio
dtoverlay=hifiberry-beocreate

# I2C
dtparam=i2c_arm=on
```

### **Ghetto Scratch (Pi Zero 2W)**

```ini
# Audio (DAC + ADC)
dtoverlay=hifiberry-dacplusadcpro

# I2C
dtparam=i2c_arm=on
```

---

## 🔍 Overlay-Status prüfen

```bash
# Alle geladenen Overlays anzeigen
vcgencmd get_config dtoverlay

# Overlay-Info
dtoverlay -l

# Overlay-Parameter
cat /sys/kernel/config/device-tree/overlays/*/status
```

---

## 📚 Weitere Ressourcen

- **Raspberry Pi Overlays:** https://github.com/raspberrypi/firmware/tree/master/boot/overlays
- **HiFiBerry Dokumentation:** https://www.hifiberry.com/docs/
- **config.txt Referenz:** [config.txt-reference.md](config.txt-reference.md)

---

**Letzte Aktualisierung:** 2025-12-07

