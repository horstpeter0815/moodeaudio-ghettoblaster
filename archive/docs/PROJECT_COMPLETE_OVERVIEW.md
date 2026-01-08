# 🎯 PROJEKT-VOLLSTÄNDIGE ÜBERSICHT

**Erstellt:** 2025-12-07  
**Zweck:** Vollständiges Verständnis des Projekts - Struktur, Architektur, Status

---

## 🎵 PROJEKT: GHETTO BLASTER (Ghetto Crew)

### **Ziel:**
High-End Audiophiles System auf Raspberry Pi 5 mit moOde Audio Custom Build

### **Hardware:**
- **Raspberry Pi 5** - Hauptsystem
- **HiFiBerry AMP100** - Audio-Verstärker
- **Waveshare DSI LCD** 1280x400 - Display
- **FT6236** - Touchscreen

### **Software:**
- **moOde Audio** - Custom Build (Debian Trixie)
- **CamillaDSP** - DSP-Verarbeitung
- **Room Correction** - Raumakustik
- **Alle Audio-Services** - Airplay, MPD, etc.

---

## 📁 PROJEKT-STRUKTUR

### **Hauptverzeichnisse:**

```
cursor/
├── custom-components/          # Custom Komponenten für Build
│   ├── configs/               # Config-Templates
│   ├── overlays/              # Device Tree Overlays
│   ├── scripts/               # Custom Scripts
│   ├── services/              # Systemd Services
│   └── presets/               # Audio-Presets
│
├── imgbuild/                   # Build-System
│   ├── moode-cfg/             # moOde Build-Konfiguration
│   │   └── stage3_03-ghettoblaster-custom/  # Unsere Custom Stage
│   ├── pi-gen-64/             # pi-gen Build-System
│   └── deploy/                # Fertige Images
│
├── moode-source/               # moOde Source (wird vom Build verwendet)
│   ├── boot/                  # Boot-Konfiguration
│   ├── lib/systemd/system/    # Systemd Services
│   └── usr/local/bin/         # Custom Scripts
│
├── services-repos/             # Service-Repositories (10 Repos, 44 MB)
│   ├── shairport-sync/        # Airplay
│   ├── mpd/                   # Music Player
│   ├── camilladsp/            # DSP
│   └── ...
│
├── drivers-repos/               # Treiber-Repositories (12 Repos, 3.8 GB)
│   ├── raspberrypi-linux/     # Pi Kernel
│   ├── waveshare-drivers/      # Display Treiber
│   ├── hifiberry-dsp/          # HiFiBerry DSP
│   └── ...
│
├── docs/                       # Dokumentation
│   ├── config-parameters/      # Config-Parameter
│   ├── hardware-setup/         # Hardware-Setup
│   └── instructions/           # Anleitungen
│
└── WISSENSBASIS/               # Wissensbasis
    ├── ANALYSES/               # Analysen
    ├── TEMPLATES/              # Templates
    └── TESTS/                  # Tests
```

---

## 🔧 BUILD-SYSTEM

### **Workflow:**

1. **Vorbereitung:**
   ```bash
   INTEGRATE_CUSTOM_COMPONENTS.sh
   ```
   - Kopiert Custom Components in `moode-source/`
   - Erstellt `config.txt.overwrite`
   - Bereitet alles für Build vor

2. **Build:**
   ```bash
   imgbuild/build.sh
   ```
   - Nutzt `pi-gen-64` Build-System
   - Stages: 0 → 1 → 2 → 3 → export
   - Stage 3.03: `ghettoblaster-custom` (unsere Komponenten)

3. **Deploy:**
   - Image in `imgbuild/deploy/*.img`
   - Auf SD-Karte brennen

---

## 🎯 GHETTO CREW SYSTEME

### **1. Ghetto Blaster** ⭐ (Aktuelles Projekt)
- **Hardware:** Raspberry Pi 5
- **Audio:** HiFiBerry AMP100
- **Display:** Waveshare 1280x400
- **OS:** moOde Custom Build
- **Rolle:** Master (Zentrale Steuerung)

### **2. Ghetto Scratch** 🎧
- **Hardware:** Raspberry Pi Zero 2W
- **Audio:** HiFiBerry ADC Pro
- **Rolle:** Slave (Vinyl Player)
- **Status:** Streamt zu Ghetto Blaster

### **3. Ghetto Boom** 🔊
- **Hardware:** Bose 901L + HiFiBerry BeoCreate
- **Rolle:** Slave (Linker Lautsprecher)
- **Steuerung:** Von Ghetto Blaster

### **4. Ghetto Mob** 🔊
- **Hardware:** Bose 901R + Custom Board
- **Rolle:** Slave (Rechter Lautsprecher)
- **Steuerung:** Von Ghetto Blaster

---

## 📋 SPEZIFIKATIONEN

### **Ghetto Blaster:**
- **Hostname:** `GhettoBlaster` (CamelCase)
- **Username:** `andre` (Linux-konform für "André")
- **Password:** `0815`
- **Display:** 1280x400 Landscape (`display_rotate=0`)
- **WLAN:** "Martin Router King" / "06082020"

---

## 🔴 BEKANNTE PROBLEME + LÖSUNGEN

### **Problem 1: SSH/Sudoers**
- **Lösung:** `fix-ssh-sudoers.service` (permanente Lösung)
- **Status:** ✅ GELÖST

### **Problem 2: Display Rotation**
- **Lösung:** `display_rotate=0` + `hdmi_force_mode=1`
- **Status:** ✅ GELÖST

### **Problem 3: Browser Start**
- **Lösung:** `disable-console.service` + `localdisplay.service`
- **Status:** ✅ GELÖST

---

## 📚 WISSENSBASEN

### **Erstellt:**
1. `REPOSITORY_KNOWLEDGE_BASE.md` - Build-Prozess, Custom Components
2. `DRIVERS_KNOWLEDGE_BASE.md` - Treiber-Probleme, Lösungen
3. `SERVICES_REPOSITORY_MANAGER.md` - Service-Repositories
4. `DRIVERS_COMPLETE_STATUS.md` - Treiber-Status

### **Bestehend:**
1. `GHETTO_CREW_SYSTEM.md` - Ghetto Crew Übersicht
2. `FINAL_NAMING.md` - System-Namen
3. `GHETTO_CREW_MASTER_SLAVE.md` - Master-Slave Architektur
4. `STRATEGIC_DECISION.md` - Strategische Entscheidungen

---

## 🎯 ARBEITSFELD-OPTIMIERUNG

### **Was ich jetzt verstehe:**
- ✅ Projekt-Struktur
- ✅ Build-System
- ✅ Custom Components
- ✅ Ghetto Crew Architektur
- ✅ Bekannte Probleme + Lösungen
- ✅ Spezifikationen

### **Was ich lernen sollte:**
- 📚 Services-Repositories analysieren
- 📚 Treiber-Repositories analysieren
- 📚 Best Practices verstehen
- 📚 Proaktive Lösungen entwickeln

---

## ✅ REFLEXION

### **Was bisher erreicht wurde:**
- ✅ Custom Build-System funktioniert
- ✅ Display funktioniert (Landscape)
- ✅ Audio funktioniert
- ✅ Services integriert
- ✅ Permanente Fixes implementiert
- ✅ Wissensbasen erstellt
- ✅ Repositories heruntergeladen

### **Was noch zu tun ist:**
- 📚 Aus Repositories lernen
- 📚 Proaktive Lösungen entwickeln
- 📚 Audio-Qualität optimieren
- 📚 High-End Features erweitern

---

**Status:** ✅ PROJEKT VOLLSTÄNDIG ÜBERSCHAUT  
**Bereit für:** Systematisches Lernen aus Repositories

