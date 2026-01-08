# PROJEKT-ÜBERSICHT

**Datum:** 1. Dezember 2025  
**Status:** In Arbeit  
**Version:** 1.0

---

## 🎯 PROJEKT-ZIEL

Stabiles Display- und Audio-Setup für Raspberry Pi 5 mit:
- ✅ Funktionsfähiges Display (HDMI)
- ✅ Funktionsfähiger Touchscreen (FT6236)
- ✅ Funktionsfähiges Audio (HiFiBerry AMP100)
- ✅ Stabile X Server-Initialisierung
- ✅ Keine Timing-Konflikte

---

## 🖥️ HARDWARE-SETUP

### **Raspberry Pi:**
- **Anzahl:** 2x
- **IP-Adressen:**
  - 192.168.178.96 (Pi 4 - RaspiOS)
  - 192.168.178.134 (Pi 5 - moOde Audio)
- **Hardware:**
  - **Pi 1:** Raspberry Pi 4 (RaspiOS - Debian 13) - **WIRD AUSGETAUSCHT**
  - **Pi 2:** Raspberry Pi 5 (moOde Audio)
- **OS:**
  - Pi 1: RaspiOS (Debian 13) - **WIRD AUSGETAUSCHT**
  - Pi 2: moOde Audio

### **Display:**
- **Typ:** HDMI-Display
- **Auflösung:** 1280x400 (PeppyMeter) / 1920x1080 (Chromium)
- **Rotation:** Landscape Left

### **Touchscreen:**
- **Typ:** FT6236
- **I2C-Bus:** Bus 13 (RP1 Controller)
- **I2C-Adresse:** 0x38

### **Audio:**
- **Typ:** HiFiBerry AMP100
- **DSP Add-on:** Verbunden via GPIO Extension
- **I2C-Bus:** Bus 13 (RP1 Controller)
- **I2C-Adresse:** 0x4d (PCM5122)

---

## 🔍 KERNPROBLEM

### **Problem:**
FT6236 Touchscreen initialisiert **vor** dem Display, was zu:
- X Server Crashes
- Display-Flickering
- Instabiler System-Start

führt.

### **Root Cause:**
- Kernel-Modul-Dependencies: FT6236 hat weniger Dependencies als VC4
- `modprobe` lädt FT6236 schneller
- FT6236 blockiert I2C-Bus 13, bevor Display bereit ist

---

## 📋 BISHERIGE VERSUCHE

### **Erfolgreich:**
- ✅ LightDM mit X11
- ✅ xinit direkt
- ✅ systemd-Service (localdisplay.service)
- ✅ FT6236 deaktiviert (funktioniert, aber kein Touchscreen)

### **Nicht erfolgreich:**
- ❌ Blacklist (funktioniert nicht - Overlay hat Priorität)
- ❌ Overlay-Reihenfolge ändern (hilft nicht - Dependencies bestimmen Reihenfolge)

---

## 💡 LÖSUNGSANSÄTZE

### **Top 5 Ansätze (in Reihenfolge):**

1. **Ansatz A: systemd-Path-Unit** ⭐⭐⭐⭐⭐
   - Event-basiert (wartet auf `/dev/dri/card0`)
   - Zeit: 2-3h | Erfolg: 90%

2. **Ansatz C: Raspberry Pi OS Full Desktop Best Practices** ⭐⭐⭐⭐⭐
   - Professionelle Basis
   - Zeit: 4-6h | Erfolg: 85%

3. **Ansatz 1: systemd-Service (Delay)** ⭐⭐⭐⭐⭐
   - Höchste Erfolgswahrscheinlichkeit (95%)
   - Zeit: 4-6h | Erfolg: 95%

4. **Ansatz 3: systemd-Targets** ⭐⭐⭐⭐
   - Professionell, explizite Dependencies
   - Zeit: 9-12h | Erfolg: 85%

5. **Ansatz B: udev-Regel für DRM** ⭐⭐⭐
   - Hardware-basiert
   - Zeit: 2-3h | Erfolg: 70%

---

## 📊 PROJEKT-STATUS

### **Abgeschlossen:**
- ✅ Hardware identifiziert
- ✅ Probleme analysiert
- ✅ Root Cause identifiziert
- ✅ Lösungsansätze entwickelt
- ✅ Top 5 Ansätze definiert

### **In Arbeit:**
- ⏳ Implementierung von Ansatz A (Path-Unit)
- ⏳ Dokumentation

### **Ausstehend:**
- ⏸️ Tests durchführen
- ⏸️ Ergebnisse dokumentieren
- ⏸️ Best Practices ableiten

---

## 💻 SOFTWARE-KOMPONENTEN

### **Entwickelte Software:**
- ✅ Device Tree Overlays (`.dts` / `.dtbo`)
- ✅ Systemd Services (`.service`)
- ✅ Shell Scripts (`.sh`)
- ✅ Python Scripts (`.py`)
- ✅ Konfigurationsdateien (`.conf`, `.txt`)

### **Technologie-Stack:**
- **OS:** Linux (RaspiOS / moOde)
- **Kernel:** Linux Kernel 6.x
- **Display:** X11 (Xorg)
- **Audio:** ALSA / MPD
- **Scripting:** Bash, Python
- **System:** systemd

---

## 🔗 VERWANDTE DOKUMENTE

- [Hardware-Dokumentation](02_HARDWARE.md)
- [Software-Entwicklung](16_SOFTWARE_ENTWICKLUNG.md)
- [Release Management](17_RELEASE_MANAGEMENT.md)
- [Probleme & Lösungen](03_PROBLEME_LOESUNGEN.md)
- [Ansätze & Vergleich](05_ANSATZE_VERGLEICH.md)
- [Implementierungs-Guides](07_IMPLEMENTIERUNGEN.md)

---

**Letzte Aktualisierung:** 1. Dezember 2025

