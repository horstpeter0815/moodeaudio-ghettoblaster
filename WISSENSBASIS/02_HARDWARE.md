# HARDWARE-DOKUMENTATION

**Datum:** 1. Dezember 2025  
**Status:** Final  
**Version:** 1.0

---

## 🖥️ RASPBERRY PI 5

### **Spezifikationen:**
- **Modell:** Raspberry Pi 5
- **Anzahl:** 2x
- **CPU:** BCM2712 (Cortex-A76)
- **RAM:** 8GB
- **GPIO:** 40-Pin Header

### **System-Informationen:**

#### **Pi 1 (192.168.178.62 - Smooth Audio):**
- **OS:** RaspiOS (Debian 13)
- **Hostname:** Smooth Audio
- **Zweck:** Display & Audio Setup

#### **Pi 2 (192.168.178.178 - Ghettoblaster):**
- **OS:** moOde Audio
- **Hostname:** Ghettoblaster
- **Zweck:** Audio-Player mit Display

---

## 🖼️ DISPLAY

### **Spezifikationen:**
- **Typ:** HDMI-Display
- **Auflösung:** 
  - Chromium: 1920x1080
  - PeppyMeter: 1280x400
- **Rotation:** Landscape Left
- **Display-Manager:** LightDM / xinit

### **Konfiguration:**
- **X Server:** Xorg 1.21.1.16
- **Display-Overlay:** `vc4-kms-v3d-pi5,noaudio`
- **DRM-Device:** `/dev/dri/card0`

---

## 👆 TOUCHSCREEN (FT6236)

### **Spezifikationen:**
- **Typ:** FT6236 Capacitive Touchscreen Controller
- **I2C-Bus:** Bus 13 (RP1 Controller)
- **I2C-Adresse:** 0x38
- **GPIO-Verbindung:** GPIO 2/3 (SDA/SCL)

### **Konfiguration:**
- **Overlay:** `dtoverlay=ft6236`
- **Kernel-Modul:** `ft6236`
- **Device:** `/dev/input/eventX`

### **Kalibrierung:**
- **Matrix:** `0 -1 1 1 0 0 0 0 1`
- **Befehl:** `xinput set-prop "FT6236" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1`

### **Bekannte Probleme:**
- ⚠️ Initialisiert vor Display (Timing-Problem)
- ⚠️ Blockiert I2C-Bus 13

---

## 🔊 AUDIO (HIFIBERRY AMP100)

### **Spezifikationen:**
- **Typ:** HiFiBerry AMP100
- **DAC:** PCM5122
- **I2C-Bus:** Bus 13 (RP1 Controller)
- **I2C-Adresse:** 0x4d (PCM5122)
- **GPIO-Verbindung:** 
  - GPIO 2/3 (SDA/SCL) - direkt verbunden
  - GPIO 17 (Reset) - via DSP Add-on
  - GPIO 4 (Mute) - via DSP Add-on

### **DSP Add-on:**
- **Verbindung:** Via GPIO Extension
- **Steuerung:** GPIO 17 (Reset), GPIO 4 (Mute)
- **I2C Kabel:** 2 Kabel (SDA/SCL) vom DSP Add-on zum AMP100
  - **SDA:** DSP Add-on → AMP100 (PCM5122 SDA Pin)
  - **SCL:** DSP Add-on → AMP100 (PCM5122 SCL Pin)
- **Status:** Aktiv

### **Konfiguration:**
- **Overlay:** `hifiberry-amp100-pi5-dsp-reset`
- **Kernel-Module:** `snd_soc_pcm512x`, `snd_soc_pcm512x_i2c`
- **Device:** `/dev/snd/pcmC0D0p`

### **Bekannte Probleme:**
- ⚠️ Reset-Fehler (-11, -5, -110)
- ⚠️ I2C-Arbitration-Konflikte
- ✅ Gelöst: DSP Add-on Reset-Service

---

## 🔌 I2C-BUSSE

### **Raspberry Pi 4 I2C-Bus-Mapping:**
- **Bus 0:** Standard I2C (GPIO 0/1)
- **Bus 1:** Standard I2C (GPIO 2/3) - **HAUPTBUS**

### **Raspberry Pi 5 I2C-Bus-Mapping:**
- **Bus 1:** Standard I2C (GPIO 2/3)
- **Bus 13:** RP1 I2C Controller (GPIO 2/3 auf RP1)
- **Bus 14:** RP1 I2C Controller (alternative)

### **Geräte-Zuordnung (Pi 4):**
- **Bus 1:**
  - FT6236 (0x38) - Touchscreen
  - PCM5122 (0x4d) - AMP100

### **Geräte-Zuordnung (Pi 5):**
- **Bus 13:**
  - FT6236 (0x38)
  - PCM5122 (0x4d)

### **Bekannte Probleme:**
- ⚠️ Pi 4: Beide Devices auf Bus 1 (GPIO 2/3)
- ⚠️ Pi 5: Bus 1 und Bus 13 könnten dasselbe sein
- ⚠️ I2C-Arbitration-Konflikte zwischen FT6236 und Display
- ⚠️ **Kabel-Problem:** DSP Add-on → AMP100 SDA/SCL Kabel müssen geprüft werden

---

## 📡 GPIO-PINS

### **Verwendete GPIO-Pins:**
- **GPIO 2/3:** I2C (SDA/SCL) - FT6236 & AMP100
- **GPIO 4:** Mute (AMP100 via DSP Add-on)
- **GPIO 14:** UART (deaktiviert für Reset-Alternative)
- **GPIO 17:** Reset (AMP100 via DSP Add-on)

### **GPIO-Status:**
- ✅ GPIO 2/3: Aktiv (I2C)
- ✅ GPIO 4: Aktiv (Mute)
- ✅ GPIO 17: Aktiv (Reset)
- ❌ GPIO 14: Deaktiviert (UART)

---

## 🔗 VERWANDTE DOKUMENTE

- [Probleme & Lösungen](03_PROBLEME_LOESUNGEN.md)
- [Test-Ergebnisse](04_TESTS_ERGEBNISSE.md)
- [Troubleshooting](08_TROUBLESHOOTING.md)

---

**Letzte Aktualisierung:** 1. Dezember 2025

