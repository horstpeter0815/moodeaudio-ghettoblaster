# Raspberry Pi Hardware - Ghetto Crew System

**Datum:** 6. Dezember 2025  
**Korrigiert:** Raspberry Pi 4 und 5 werden verwendet

---

## 🎯 HARDWARE-ÜBERSICHT

### **Raspberry Pi 5:**
- **Ghetto Blaster** (Hauptsystem)
- **Zentrales Element** mit Display
- **moOde Audio Player** als Basis
- **HiFiBerry AMP100** HAT
- **FT6236 Touchscreen** (1280x400)
- **Dual Display Support** (DSI + HDMI)

### **Raspberry Pi 4:**
- **Ghetto Boom** (Bose 901L - Linker Kanal)
  - HiFiBerry BeoCreate HAT
  - Aktiver Lautsprecher mit 4x 4"-Treibern
  - 2x 60W Kanäle
  
- **GhettoMoob** (Bose 901R - Rechter Kanal)
  - Selbst-designed HAT
  - Aktiver Lautsprecher mit 4x 4"-Treibern
  - 2x 60W Kanäle

### **Raspberry Pi Zero 2W:**
- **Ghetto Scratch** (Vinyl Player)
- **HiFiBerry DAC+ ADC Pro**
- **Streaming zu Ghetto Blaster**
- **Zukünftig:** Turntable-Kontrolle via Ghetto Blaster Display

---

## 📊 RASPBERRY PI 5 (Ghetto Blaster)

### **Hardware-Komponenten:**
- **Board:** Raspberry Pi 5
- **Display:** 1280x400 Custom Display
- **Touchscreen:** FT6236 I2C Touch Controller
- **Audio HAT:** HiFiBerry AMP100
  - PCM5122 DAC
  - TAS5756M Amplifier
- **Netzwerk:** Ethernet (LAN-Kabel)

### **Custom Components:**
- **Device Tree Overlay:** `ghettoblaster-ft6236.dtbo`
- **Device Tree Overlay:** `ghettoblaster-amp100.dtbo`
- **Display Rotation:** 270° (display_rotate=3)
- **I2C Baudrate:** 100000

### **Software:**
- **OS:** Custom moOde Audio Image
- **Player:** MPD (Music Player Daemon)
- **Audio:** ALSA (192kHz/32-bit)
- **Display:** Chromium Kiosk Mode
- **Visualisierung:** PeppyMeter + Extended Displays

---

## 📊 RASPBERRY PI 4

### **Ghetto Boom (Linker Kanal):**
- **Board:** Raspberry Pi 4
- **Audio HAT:** HiFiBerry BeoCreate
- **Lautsprecher:** Bose 901L
- **Treiber:** 8x Bose 901 Treiber (4,5-Zoll, hinten) + Fostex T90A Super Tweeter (vorne)
- **Kanal:** Links (2x 60W Kanäle)

### **GhettoMoob (Rechter Kanal):**
- **Board:** Raspberry Pi 4
- **Audio HAT:** Selbst-designed
- **Lautsprecher:** Bose 901R
- **Treiber:** 8x Bose 901 Treiber (4,5-Zoll, hinten) + Fostex T90A Super Tweeter (vorne)
- **Kanal:** Rechts (2x 60W Kanäle)

---

## 📊 RASPBERRY PI ZERO 2W (Ghetto Scratch)

### **Hardware-Komponenten:**
- **Board:** Raspberry Pi Zero 2W
- **Audio HAT:** HiFiBerry DAC+ ADC Pro
- **Netzwerk:** WiFi (für Streaming)

### **Funktionalität:**
- **Aktuell:** Streaming zu Ghetto Blaster
- **Zukünftig:** Turntable-Kontrolle via Ghetto Blaster Display

---

## 🔧 TECHNISCHE UNTERSCHIEDE

### **Raspberry Pi 5 vs Pi 4:**
- **Pi 5:** Neuere Hardware, bessere Performance
- **Pi 5:** Mehr RAM-Optionen
- **Pi 5:** PCIe Support
- **Pi 5:** Besserer I/O-Durchsatz

### **Relevanz für Build:**
- **Custom Image:** Primär für Pi 5 optimiert
- **Kompatibilität:** Kann auch auf Pi 4 laufen (muss getestet werden)

---

## 📝 NOTIZEN

### **Build-Konfiguration:**
- **Aktuell:** Pi 5 optimiert
- **Zukünftig:** Multi-Platform Support (Pi 4 + Pi 5)

### **Hardware-Spezifika:**
- **Pi 5:** `dtoverlay=vc4-kms-v3d-pi5,noaudio`
- **Pi 4:** Könnte `vc4-kms-v3d` benötigen
- **Device Tree:** Pi-spezifische Overlays

---

## ✅ STATUS

**Dokumentiert:**
- ✅ Raspberry Pi 5 (Ghetto Blaster)
- ✅ Raspberry Pi 4 (Ghetto Boom + GhettoMoob)
- ✅ Raspberry Pi Zero 2W (Ghetto Scratch)

**Korrigiert:**
- ✅ Beide Plattformen (Pi 4 + Pi 5) werden verwendet

---

**Wichtig:** Custom Build ist primär für Pi 5, aber Pi 4 Kompatibilität sollte geprüft werden!

