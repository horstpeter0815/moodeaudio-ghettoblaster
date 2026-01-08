# COMPLETE HIFI SYSTEM ARCHITECTURE - GHETTO CREW

**Datum:** 3. Dezember 2025, 00:15 Uhr  
**System-Name:** Ghetto Crew  
**Projekt:** Komplettes HiFi-System mit Ghetto Blaster als Zentrale  
**Status:** ARCHITECTURE PLANNING

---

## 🎯 SYSTEM-ÜBERSICHT

### **Zentrale Komponente:**
- **Ghetto Blaster** (Raspberry Pi 5)
  - moOde Audio (Ghetto OS)
  - 1280x400 Display
  - Touchscreen (FT6236)
  - HiFiBerry AMP100
  - Position: Unter dem Fernseher als "kleines Radio"

### **Audio-Quellen:**
- **Ghetto Scratch** (Raspberry Pi Zero 2W)
  - HiFiBerry ADC Pro
  - Web-Stream zu Ghetto Blaster

### **Aktive Lautsprecher:**
- **Ghetto Boom** (Bose 901L)
  - Raspberry Pi 4
  - HiFiBerry BeoCreate
  - Linker Kanal (2x 60W)
  
- **GhettoMoob** (Bose 901R)
  - Raspberry Pi 4
  - Selbst-designed HAT
  - Rechter Kanal (2x 60W)
  - **Witz:** "Boom" rückwärts = "Mob" 😄

---

## 🎵 GHETTO CREW

**Das komplette HiFi-System heißt "Ghetto Crew"**

---

## 🏗️ SYSTEM-ARCHITEKTUR

```
                    GHETTO CREW
                         │
┌─────────────────────────────────────────────────────────┐
│                    GHETTO BLASTER                       │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Raspberry Pi 5                                  │   │
│  │  - moOde Audio (Ghetto OS)                       │   │
│  │  - 1280x400 Display                              │   │
│  │  - Touchscreen (FT6236)                          │   │
│  │  - HiFiBerry AMP100                              │   │
│  │  - PinMultiboot (später)                        │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  Multi-Boot Systeme (später):                           │
│  - Raspberry Pi OS Full                                 │
│  - Retro Gaming Console                                 │
│  - DietPi                                               │
│  - ~10 Systeme insgesamt                                │
└─────────────────────────────────────────────────────────┘
           │                    │                    │
           │                    │                    │
           ▼                    ▼                    ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  GHETTO SCRATCH  │  │  GHETTO BOOM     │  │  GHETTO MOB     │
│                  │  │                  │  │                  │
│  Pi Zero 2W      │  │  Bose 901L      │  │  Bose 901R      │
│  HiFiBerry       │  │  HiFiBerry       │  │  Self-designed   │
│  ADC Pro         │  │  BeoCreate      │  │                  │
│                  │  │                  │  │                  │
│  Web-Stream ────┼──┼─► Ghetto Blaster │  │                  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 📋 KOMPONENTEN-DETAILS

### **1. GHETTO BLASTER (Zentrale)**

#### **Hardware:**
- Raspberry Pi 5
- 1280x400 Display (WaveShare)
- FT6236 Touchscreen
- HiFiBerry AMP100
- Position: Unter Fernseher

#### **Software:**
- **Aktuell:** moOde Audio (Ghetto OS)
- **Später:** PinMultiboot mit ~10 Systemen:
  1. moOde Audio (Ghetto OS) ✅
  2. Raspberry Pi OS Full
  3. Retro Gaming Console
  4. DietPi
  5. [Weitere 6 Systeme - zu diskutieren]

#### **Funktionen:**
- Audio-Player (moOde)
- Display für Status/Control
- Touchscreen-Interface
- Web-UI für Remote-Control
- **Später:** Multi-Boot Management

#### **Integration:**
- Empfängt Web-Stream von Vinyl Player
- Steuert Ghetto Box L & R
- Display umschaltbar für Lautsprecher-Management

---

### **2. GHETTO SCRATCH (Vinyl Player)**

#### **Hardware:**
- Raspberry Pi Zero 2W
- HiFiBerry ADC Pro
- Analog-Digital-Wandler

#### **Funktion:**
- Vinyl-Platten digitalisieren
- Web-Stream zu Ghetto Blaster
- Integration in moOde GUI

#### **Integration:**
- Web-Stream über HTTP/HTTPS
- In moOde als Radio-Stream
- Grafische Auswahl im Web-UI
- PeppyMeter Visualisierung

---

### **3. GHETTO BOOM (Bose 901L)**

#### **Hardware:**
- Bose 901L Lautsprecher
- Fostex T90A Super Tweeter (jeder enthält einen)
- Fostex FE108EΣ Full Range (Front)
- HiFiBerry BeoCreate
- Linker Kanal

#### **Software:**
- BeoCreate Software (bereits vorhanden)
- Web-Interface
- MPD/Streaming-Support

#### **Integration:**
- Steuerung von Ghetto Blaster
- Web Player Interface
- Display-Umschaltung möglich

---

### **4. GHETTO MOB (Bose 901R)**

#### **Hardware:**
- Bose 901R Lautsprecher
- Fostex T90A Super Tweeter (jeder enthält einen)
- Fostex FE108EΣ Full Range (Front)
- Selbst-designed Board
- Rechter Kanal

#### **Software:**
- Custom Software (bereits vorhanden)
- Web-Interface
- MPD/Streaming-Support

#### **Integration:**
- Steuerung von Ghetto Blaster
- Web Player Interface
- Display-Umschaltung möglich

---

## 🎛️ STEUERUNG & MANAGEMENT

### **Option A: Display-Umschaltung (Aktuell geplant)**
- Ghetto Blaster Display umschaltbar
- Zwischen moOde UI und Lautsprecher-Management
- Settings für Ghetto Box L & R

### **Option B: Oversized Control (Ideale Lösung)**
- Einheitliche Steuerung für beide Lautsprecher
- Gleichzeitige Kontrolle
- Bessere UX

### **Empfehlung:**
- **Kurzfristig:** Display-Umschaltung implementieren
- **Langfristig:** Oversized Control entwickeln

---

## 🔄 INTEGRATION PLAN

### **Phase 1: Ghetto Blaster (Aktuell)**
- ✅ moOde Custom Build
- ✅ Display & Touchscreen
- ✅ Audio (AMP100)
- ✅ Vinyl Stream Integration (vorbereitet)

### **Phase 2: Ghetto Scratch (Vinyl Player)**
- ⏳ Pi Zero 2W Setup
- ⏳ HiFiBerry ADC Pro Integration
- ⏳ Web-Stream Implementation
- ⏳ moOde GUI Integration

### **Phase 3: Ghetto Boom & Mob (Lautsprecher)**
- ⏳ BeoCreate Software Integration
- ⏳ Custom Board Software Integration
- ⏳ Web Player Interface
- ⏳ Display-Umschaltung

### **Phase 4: Multi-Boot (Später)**
- ⏳ PinMultiboot Installation
- ⏳ Raspberry Pi OS Full
- ⏳ Retro Gaming Console
- ⏳ DietPi
- ⏳ Weitere Systeme

---

## 📊 SYSTEM-ANFORDERUNGEN

### **Ghetto Blaster:**
- Raspberry Pi 5 ✅
- 1280x400 Display ✅
- Touchscreen ✅
- HiFiBerry AMP100 ✅
- **Später:** Größere SD/SSD für Multi-Boot

### **Ghetto Scratch:**
- Raspberry Pi Zero 2W
- HiFiBerry ADC Pro
- Netzwerk (WLAN/Ethernet)

### **Ghetto Boom:**
- Bose 901L
- HiFiBerry BeoCreate
- Netzwerk

### **GhettoMoob:**
- Bose 901R
- Custom Board
- Netzwerk

---

## 🎯 NÄCHSTE SCHRITTE

### **Sofort:**
1. ✅ Ghetto Blaster Custom Build fertigstellen
2. ⏳ Vinyl Player Integration vorbereiten
3. ⏳ Ghetto Box L & R Integration planen

### **Später:**
1. ⏳ PinMultiboot Setup
2. ⏳ Multi-Boot Systeme installieren
3. ⏳ Oversized Control entwickeln

---

---

## 🏭 3D PRINTING DEPARTMENT (NEW)

### **Geschäftserweiterung:**
- **Aktuell:** Software-Entwicklung + Hardware-Komponenten
- **Neu:** 3D-Druck Produktion
- **Ziel:** Eigene Produktionsabteilung

### **Fokus:**
- BOSE Wave Radio Komponenten
- Hardware-Gehäuse
- Custom Enclosures
- Prototyping

### **Personal:**
- 3D Printing Specialist (Blender-Experte)
- Produktionsplanung

### **Software:**
- Blender (sehr gute Beherrschung erforderlich)
- 3D-Scan-Verarbeitung
- STL/OBJ/Blend-Formate

### **Status:**
- ✅ Blender Repository geklont
- ✅ BOSE Wave Radio 3D-Scan gefunden
- ⏳ Scan analysieren und verstehen
- ✅ Alle Informationen gesammelt

**Siehe:** `3D_PRINTING_DEPARTMENT_PLAN.md` für Details

---

## 🔊 ACOUSTICS DEPARTMENT (NEW)

### **Geschäftserweiterung:**
- **Aktuell:** Software-Entwicklung + Hardware-Komponenten + 3D-Druck
- **Neu:** Akustik-Entwicklung & Produktentwicklung
- **Ziel:** Big Wave System entwickeln

### **Projekt: Big Wave System**
- **Basis:** BOSE Wave Channel Design
- **Typ:** Back-loaded Horn System
- **Treiber:** Full-Range (< 10 cm Durchmesser)
- **Bass:** Horn-Loading
- **Qualität:** High-End

### **Personal:**
- Acoustics Engineer
  - Back-loaded Horn Expertise
  - Treiber-Auswahl & Integration
  - Horn-Berechnungen
  - System-Design

### **Aktuelle Aufgaben:**
- ⏳ Extensive Marktstudie: Full-Range Treiber (< 10 cm)
- ⏳ Treiber-Vorschläge (High-End)
- ⏳ BOSE Wave Channel Analyse vertiefen
- ⏳ Horn-Berechnungs-Software integrieren

### **Status:**
- ✅ Abteilung eingerichtet
- ⏳ Marktstudie läuft
- ⏳ BOSE Wave Analyse startet
- ⏳ Horn-Software wird bereitgestellt

**Siehe:** `ACOUSTICS_DEPARTMENT_PLAN.md` für Details

---

**Status:** 🏗️ ARCHITECTURE PLANNING COMPLETE  
**Nächster Schritt:** Integration Details ausarbeiten

