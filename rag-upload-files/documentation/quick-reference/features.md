# Features - Übersicht

**Alle implementierten Features im Ghetto Crew System**

---

## ✅ Implementierte Features

### **1. Flat EQ Preset**

**Beschreibung:** Factory Flat EQ für alle Treiber (Bose 901 + Fostex)

**Status:** ✅ Implementiert

**Zugriff:**
- Web-UI: Audio Settings → "Flat EQ (Factory Settings)" Checkbox
- API: `POST /command/ghettoblaster-flat-eq.php?cmd=toggle`

**Details:**
- Kompensiert Frequency Response für gerade Linie
- 11-Band EQ (20Hz - 20kHz)
- Ein/Aus Toggle

---

### **2. Room Correction Wizard**

**Beschreibung:** Browser-basierte Raumkorrektur mit Mobile Phone

**Status:** ✅ Implementiert

**Zugriff:**
- Web-UI: Audio Settings → "Run Wizard" Button
- 5-Step Wizard:
  1. Einleitung
  2. Test-Tone Playback
  3. Measurement (File Upload oder Browser Recording)
  4. Analysis & Filter Generation
  5. Apply & A/B Test

**Features:**
- Test-Tone Sweep (20Hz - 20kHz)
- File Upload (WAV)
- Browser Recording (getUserMedia)
- Frequency Response Graph
- FIR Filter Generation
- A/B Test (Before/After)

**Details:**
- API: `/command/room-correction-wizard.php`
- Filters: `/var/lib/camilladsp/convolution/`

---

### **3. PeppyMeter Touch Gestures**

**Beschreibung:** Touch-Gesten für PeppyMeter Display

**Status:** ✅ Implementiert

**Gestures:**
- **Double-Tap:** Wechsel zwischen Power Meter ↔ Temp ↔ Stream Info
- **Single-Tap:** PeppyMeter Ein/Aus

**Details:**
- Script: `/opt/peppymeter/extended-displays.py`
- Service: `peppymeter-extended-displays.service`
- Touchscreen: FT6236 (I2C)

---

### **4. CamillaDSP Integration**

**Beschreibung:** Convolution Filters für Room Correction

**Status:** ✅ Implementiert

**Features:**
- Quick Convolution Support
- FIR Filter (WAV Format)
- Real-time Processing
- A/B Testing

**Details:**
- Config: `/etc/camilladsp/config.yml`
- Filters: `/var/lib/camilladsp/convolution/`

---

## ⏳ Geplante Features

### **5. MM/MC Phono Presets**

**Beschreibung:** Phono-Equalisierung für Ghetto Scratch

**Status:** ⏳ Geplant

**Features:**
- MM (Moving Magnet) Presets
- MC (Moving Coil) Presets
- DSP Equalization
- REST API für Steuerung

**Hardware:**
- HiFiBerry DAC+ ADC Pro
- Raspberry Pi Zero 2W

---

### **6. Multi-Room Audio**

**Beschreibung:** Synchronisierung zwischen Ghetto Blaster, Boom, Moob

**Status:** ⏳ Geplant

**Features:**
- Synchron Playback
- Volume Control
- Source Selection

---

## 📊 Feature-Matrix

| Feature | Status | Device | Web-UI | API |
|---------|--------|--------|--------|-----|
| Flat EQ Preset | ✅ | Alle | ✅ | ✅ |
| Room Correction | ✅ | Alle | ✅ | ✅ |
| PeppyMeter Touch | ✅ | Blaster | ✅ | - |
| CamillaDSP | ✅ | Alle | ✅ | ✅ |
| MM/MC Phono | ⏳ | Scratch | ⏳ | ⏳ |
| Multi-Room | ⏳ | Alle | ⏳ | ⏳ |

---

## 🔗 Weitere Ressourcen

- **Hardware:** [hardware-overview.md](hardware-overview.md)
- **Commands:** [commands.md](commands.md)
- **Config:** [../config-parameters/](../config-parameters/)

---

**Letzte Aktualisierung:** 2025-12-07

