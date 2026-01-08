# Hardware-Setup Anleitung

**Schritt-für-Schritt Anleitung zum Hardware-Setup aller Ghetto Crew Komponenten**

---

## 📋 Übersicht

| Device | Pi | HAT | Display | Setup-Zeit |
|--------|----|-----|--------|------------|
| **Ghetto Blaster** | Pi 5 | AMP100 | 1280x400 Touch | ~30 Min |
| **Ghetto Boom** | Pi 4 | BeoCreate | - | ~20 Min |
| **Ghetto Moob** | Pi 4 | BeoCreate | - | ~20 Min |
| **Ghetto Scratch** | Pi Zero 2W | DAC+ ADC Pro | - | ~15 Min |

---

## 🔊 Ghetto Blaster (Pi 5)

### **Hardware-Komponenten**
- Raspberry Pi 5 (8GB)
- HiFiBerry AMP100 HAT
- 1280x400 Touchscreen Display
- FT6236 Touch Controller
- 2x Bose 901 Series 6
- Fostex Mid/Tweeter

### **Schritt 1: HAT montieren**

1. GPIO-Header auf Pi 5 prüfen
2. HiFiBerry AMP100 HAT auf GPIO stecken
3. Standoffs montieren (falls vorhanden)

### **Schritt 2: Display anschließen**

1. HDMI-Kabel an Pi 5 HDMI-Port
2. Display an HDMI-Kabel
3. Touchscreen-Kabel an I2C-Pins (SDA/SCL)

### **Schritt 3: Audio anschließen**

1. Lautsprecher an AMP100 Output
2. 2x Bose 901 + Fostex an AMP100

### **Schritt 4: Stromversorgung**

1. USB-C Power Supply (5V, 5A) an Pi 5
2. System booten

### **Config prüfen**

```bash
# config.txt sollte enthalten:
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100,automute
hdmi_cvt=1280 400 60 6 0 0 0
display_rotate=3
```

**Details:** [../hardware-setup/ghetto-blaster.md](../hardware-setup/ghetto-blaster.md)

---

## 🔊 Ghetto Boom (Pi 4)

### **Hardware-Komponenten**
- Raspberry Pi 4 (4GB)
- HiFiBerry BeoCreate HAT
- 8x Bose 901 Original-Treiber
- Fostex Mid/Tweeter

### **Schritt 1: HAT montieren**

1. GPIO-Header auf Pi 4 prüfen
2. HiFiBerry BeoCreate HAT auf GPIO stecken
3. Standoffs montieren

### **Schritt 2: Audio anschließen**

1. 8x Bose 901 Treiber an BeoCreate Output
2. Fostex Mid/Tweeter an BeoCreate Output

### **Schritt 3: Stromversorgung**

1. USB-C Power Supply (5V, 3A) an Pi 4
2. System booten

### **Config prüfen**

```bash
# config.txt sollte enthalten:
dtoverlay=hifiberry-beocreate
```

**Details:** [../hardware-setup/ghetto-boom.md](../hardware-setup/ghetto-boom.md)

---

## 🔊 Ghetto Moob (Pi 4)

### **Hardware-Komponenten**
- Raspberry Pi 4 (4GB)
- HiFiBerry BeoCreate HAT
- 8x Bose 901 Original-Treiber
- Fostex Mid/Tweeter

### **Setup**

Identisch zu Ghetto Boom.

**Details:** [../hardware-setup/ghetto-moob.md](../hardware-setup/ghetto-moob.md)

---

## 🎚️ Ghetto Scratch (Pi Zero 2W)

### **Hardware-Komponenten**
- Raspberry Pi Zero 2W
- HiFiBerry DAC+ ADC Pro HAT
- Phono Preamp (MM/MC)

### **Schritt 1: HAT montieren**

1. GPIO-Header auf Pi Zero 2W prüfen
2. HiFiBerry DAC+ ADC Pro HAT auf GPIO stecken
3. Standoffs montieren

### **Schritt 2: Audio anschließen**

1. Line Out an Verstärker
2. Phono Input an ADC

### **Schritt 3: Stromversorgung**

1. Micro-USB Power Supply (5V, 2.5A) an Pi Zero 2W
2. System booten

### **Config prüfen**

```bash
# config.txt sollte enthalten:
dtoverlay=hifiberry-dacplusadcpro
```

**Details:** [../hardware-setup/ghetto-scratch.md](../hardware-setup/ghetto-scratch.md)

---

## ✅ Setup-Verifikation

### **1. Hardware erkannt?**

```bash
# HAT-Status
vcgencmd get_config dtoverlay

# Audio-Geräte
aplay -l
arecord -l
```

### **2. Display funktioniert?** (nur Ghetto Blaster)

```bash
# Display-Info
tvservice -s
```

### **3. Touchscreen funktioniert?** (nur Ghetto Blaster)

```bash
# Touchscreen-Test
evtest /dev/input/event0
```

### **4. Audio funktioniert?**

```bash
# Test-Ton
speaker-test -c 2 -t wav
```

---

## 🔧 Troubleshooting

### **Problem: HAT wird nicht erkannt**

**Lösung:**
- GPIO-Verbindung prüfen
- config.txt prüfen (dtoverlay)
- Neustart

### **Problem: Display zeigt nichts**

**Lösung:**
- HDMI-Kabel prüfen
- config.txt prüfen (hdmi_cvt)
- Anderes HDMI-Kabel testen

### **Problem: Touchscreen funktioniert nicht**

**Lösung:**
- I2C-Verbindung prüfen
- ft6236-delay.service Status prüfen
- Touchscreen-Kabel prüfen

### **Problem: Kein Audio**

**Lösung:**
- HAT korrekt montiert?
- Audio-Output in Web-UI prüfen
- Lautstärke prüfen
- MPD Status prüfen

---

## 📚 Weitere Ressourcen

- **Hardware-Übersicht:** [../quick-reference/hardware-overview.md](../quick-reference/hardware-overview.md)
- **Config-Parameter:** [../config-parameters/](../config-parameters/)
- **Commands:** [../quick-reference/commands.md](../quick-reference/commands.md)

---

**Letzte Aktualisierung:** 2025-12-07

