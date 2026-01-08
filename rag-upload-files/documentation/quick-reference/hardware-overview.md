# Hardware-Übersicht - Ghetto Crew

**Komplette Hardware-Übersicht aller Ghetto Crew Komponenten**

---

## 🎯 System-Übersicht

| Device | Raspberry Pi | HAT | Display | Audio-Output | Audio-Input |
|--------|--------------|-----|---------|--------------|-------------|
| **Ghetto Blaster** | Pi 5 | HiFiBerry AMP100 | 1280x400 Touch | 2x Bose 901 + Fostex | - |
| **Ghetto Boom** | Pi 4 | HiFiBerry BeoCreate | - | 8x Bose 901 + Fostex | - |
| **Ghetto Moob** | Pi 4 | HiFiBerry BeoCreate | - | 8x Bose 901 + Fostex | - |
| **Ghetto Scratch** | Pi Zero 2W | HiFiBerry DAC+ ADC Pro | - | Line Out | Phono (MM/MC) |

---

## 🔊 Ghetto Blaster (Pi 5)

### **Hardware**
- **Raspberry Pi:** 5 (8GB RAM)
- **HAT:** HiFiBerry AMP100
- **Display:** 1280x400 Touchscreen (FT6236)
- **Audio:** 2x Bose 901 Series 6 + Fostex Mid/Tweeter

### **Features**
- ✅ PeppyMeter Display
- ✅ Touch-Gesten (Double-Tap, Single-Tap)
- ✅ Flat EQ Preset
- ✅ Room Correction

### **Config**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100,automute
hdmi_cvt=1280 400 60 6 0 0 0
display_rotate=3
```

**Details:** [../hardware-setup/ghetto-blaster.md](../hardware-setup/ghetto-blaster.md)

---

## 🔊 Ghetto Boom (Pi 4)

### **Hardware**
- **Raspberry Pi:** 4 (4GB RAM)
- **HAT:** HiFiBerry BeoCreate
- **Display:** Kein Display
- **Audio:** 8x Bose 901 Original-Treiber (4.5", Helical Voice Coil) + Fostex Mid/Tweeter
- **System:** Back-loaded Horn (Bose 901 Serie 6 Original)

### **Features**
- ✅ Multi-Channel Audio
- ✅ Flat EQ Preset
- ✅ Room Correction

### **Config**
```ini
dtoverlay=hifiberry-beocreate
```

**Details:** [../hardware-setup/ghetto-boom.md](../hardware-setup/ghetto-boom.md)

---

## 🔊 Ghetto Moob (Pi 4)

### **Hardware**
- **Raspberry Pi:** 4 (4GB RAM)
- **HAT:** HiFiBerry BeoCreate
- **Display:** Kein Display
- **Audio:** 8x Bose 901 Original-Treiber (4.5", Helical Voice Coil) + Fostex Mid/Tweeter
- **System:** Back-loaded Horn (Bose 901 Serie 6 Original)

### **Features**
- ✅ Multi-Channel Audio
- ✅ Flat EQ Preset
- ✅ Room Correction

### **Config**
```ini
dtoverlay=hifiberry-beocreate
```

**Details:** [../hardware-setup/ghetto-moob.md](../hardware-setup/ghetto-moob.md)

---

## 🎚️ Ghetto Scratch (Pi Zero 2W)

### **Hardware**
- **Raspberry Pi:** Zero 2W
- **HAT:** HiFiBerry DAC+ ADC Pro
- **Display:** Kein Display
- **Audio-Output:** Line Out (DAC)
- **Audio-Input:** Phono Preamp (MM/MC)

### **Features**
- ✅ MM/MC Phono Presets (geplant)
- ✅ DSP Equalization für Phono
- ✅ REST API für Steuerung

### **Config**
```ini
dtoverlay=hifiberry-dacplusadcpro
```

**Details:** [../hardware-setup/ghetto-scratch.md](../hardware-setup/ghetto-scratch.md)

---

## 📊 Treiber-Spezifikationen

### **Bose 901 Series 6 Original**
- **Größe:** 4.5 Zoll
- **Typ:** Helical Voice Coil
- **Verwendung:** Ghetto Boom/Moob (8x pro System)
- **System:** Back-loaded Horn

### **Fostex Mid-Tones**
- **Verwendung:** Alle Systeme (Mid-Bereich)

### **Fostex Tweeters**
- **Verwendung:** Alle Systeme (High-Bereich)

---

## 🔌 HAT-Übersicht

| HAT | Verwendung | Features |
|-----|------------|----------|
| **HiFiBerry AMP100** | Ghetto Blaster | 2x50W Class D, I2S, Auto-Mute |
| **HiFiBerry BeoCreate** | Ghetto Boom/Moob | Multi-Channel, 8x Output |
| **HiFiBerry DAC+ ADC Pro** | Ghetto Scratch | DAC + ADC, Phono Preamp |

---

## 📐 Display-Spezifikationen

### **Ghetto Blaster Display**
- **Auflösung:** 1280x400
- **Refresh Rate:** 60Hz
- **Touch:** FT6236 Controller
- **Rotation:** 180° (display_rotate=3)

---

## 🔗 Weitere Ressourcen

- **Hardware-Specs:** `RASPBERRY_PI_HARDWARE_SPECS.md`
- **System-Architektur:** `COMPLETE_HIFI_SYSTEM_ARCHITECTURE.md`
- **Config-Parameter:** [../config-parameters/](../config-parameters/)

---

**Letzte Aktualisierung:** 2025-12-07

