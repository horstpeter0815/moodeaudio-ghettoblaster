# 📚 Ghetto Crew - Zentrales Wiki & Konfiguration

**Zentrales Verzeichnis für alle wichtigen Parameter, Anweisungen und Dokumentationen**

---

## 📂 Struktur

```
docs/
├── README.md                          ← Du bist hier
├── config-parameters/                 ← Alle Konfigurationsparameter
│   ├── config.txt-reference.md       ← config.txt Parameter-Referenz
│   ├── dtoverlay-reference.md         ← Device Tree Overlays
│   ├── moOde-settings.md              ← moOde-spezifische Einstellungen
│   └── hardware-specific.md           ← Hardware-spezifische Configs
├── instructions/                      ← Schritt-für-Schritt Anleitungen
│   ├── build-process.md               ← Build-Prozess
│   ├── deployment.md                  ← Image-Deployment
│   ├── hardware-setup.md              ← Hardware-Setup
│   └── troubleshooting.md             ← Fehlerbehebung
├── quick-reference/                   ← Schnellreferenzen
│   ├── hardware-overview.md           ← Hardware-Übersicht
│   ├── commands.md                   ← Wichtige Befehle
│   └── features.md                    ← Feature-Übersicht
└── hardware-setup/                    ← Hardware-Details
    ├── ghetto-blaster.md              ← Pi 5 Setup
    ├── ghetto-boom.md                 ← Pi 4 (Boom)
    ├── ghetto-moob.md                 ← Pi 4 (Moob)
    └── ghetto-scratch.md              ← Pi Zero 2W Setup
```

---

## 🚀 Quick Links

### **Konfiguration**
- [config.txt Parameter-Referenz](config-parameters/config.txt-reference.md)
- [Device Tree Overlays](config-parameters/dtoverlay-reference.md)
- [moOde Settings](config-parameters/moOde-settings.md)

### **Anleitungen**
- [Build-Prozess](instructions/build-process.md)
- [Deployment](instructions/deployment.md)
- [Hardware-Setup](instructions/hardware-setup.md)

### **Hardware**
- [Hardware-Übersicht](quick-reference/hardware-overview.md)
- [Ghetto Blaster (Pi 5)](hardware-setup/ghetto-blaster.md)
- [Ghetto Boom/Moob (Pi 4)](hardware-setup/ghetto-boom.md)
- [Ghetto Scratch (Pi Zero 2W)](hardware-setup/ghetto-scratch.md)

---

## 📋 Wichtige Parameter (Kurzübersicht)

### **config.txt - Wichtigste Parameter**

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `dtoverlay=hifiberry-amp100` | `automute` | HiFiBerry AMP100 HAT |
| `dtoverlay=vc4-kms-v3d-pi5` | `noaudio` | Pi 5 Display (KMS) |
| `hdmi_cvt` | `1280 400 60 6 0 0 0` | Custom Display Resolution |
| `display_rotate` | `3` | Display Rotation (180°) |
| `dtparam=i2c_arm` | `on` | I2C aktivieren |
| `dtparam=i2s` | `on` | I2S aktivieren |

**Vollständige Liste:** [config.txt-reference.md](config-parameters/config.txt-reference.md)

---

## 🎯 Hardware-Übersicht

| Device | Raspberry Pi | HAT | Display | Audio |
|--------|--------------|-----|---------|-------|
| **Ghetto Blaster** | Pi 5 | HiFiBerry AMP100 | 1280x400 Touch | 2x Bose 901 + Fostex |
| **Ghetto Boom** | Pi 4 | HiFiBerry BeoCreate | - | 8x Bose 901 + Fostex |
| **Ghetto Moob** | Pi 4 | HiFiBerry BeoCreate | - | 8x Bose 901 + Fostex |
| **Ghetto Scratch** | Pi Zero 2W | HiFiBerry DAC+ ADC Pro | - | Phono Preamp |

**Details:** [hardware-overview.md](quick-reference/hardware-overview.md)

---

## 🔧 Features

- ✅ **Flat EQ Preset** - Factory Flat EQ für alle Treiber
- ✅ **Room Correction Wizard** - Browser-basierte Raumkorrektur
- ✅ **PeppyMeter Touch Gestures** - Touch-Gesten für Display
- ✅ **MM/MC Phono Presets** - Vinyl-Equalisierung (geplant)
- ✅ **CamillaDSP Integration** - Convolution Filters

**Details:** [features.md](quick-reference/features.md)

---

## 📖 Weitere Dokumentation

- **Projekt-Status:** `PROJECT_STATUS_OVERVIEW.md`
- **System-Architektur:** `COMPLETE_HIFI_SYSTEM_ARCHITECTURE.md`
- **Hardware-Specs:** `RASPBERRY_PI_HARDWARE_SPECS.md`
- **Build-Status:** `BUILD_SUCCESS_SUMMARY.md`

---

**Letzte Aktualisierung:** 2025-12-07

