# AUTOMATIC ROOM CORRECTION - PLAN

**Datum:** 2. Dezember 2025  
**Status:** PLAN  
**Zweck:** Automatische Raumkorrektur mit RoomEQWizard RTA und Handy-Mikrofon

---

## 🎯 ANFORDERUNGEN

**Ziel:**
- ✅ Rosa Rauschen abspielen
- ✅ Handy-Mikrofon am Hörplatz empfangen
- ✅ Real Time Analyzer misst Frequenzgang
- ✅ Automatisch DSP/Filter generieren
- ✅ Filter auf HiFiBerryOS DSP anwenden

---

## 📋 SYSTEM-ARCHITEKTUR

```
┌─────────────────────────────────────────────────────────┐
│              HiFiBerryOS (Pi 4)                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                │
│  │ Rosa Rauschen│───▶│ Audio Output │                │
│  │ Generator    │    │ (HiFiBerry)  │                │
│  └──────────────┘    └──────────────┘                │
│         │                    │                        │
│         │                    │                        │
│         ▼                    ▼                        │
│  ┌──────────────────────────────────────┐            │
│  │         Raum (Akustik)               │            │
│  └──────────────────────────────────────┘            │
│         │                    │                        │
│         │                    │                        │
│         ▼                    ▼                        │
│  ┌──────────────┐    ┌──────────────┐                │
│  │ Handy-Mikrofon│───▶│ RTA (Real    │                │
│  │ (Hörplatz)    │    │ Time Analyzer)│                │
│  └──────────────┘    └──────────────┘                │
│         │                    │                        │
│         │                    │                        │
│         └──────────┬──────────┘                        │
│                    │                                   │
│                    ▼                                   │
│         ┌──────────────────────┐                      │
│         │  Frequenzgang-Daten  │                      │
│         │  (JSON Format)       │                      │
│         └──────────────────────┘                      │
│                    │                                   │
│                    ▼                                   │
│         ┌──────────────────────┐                      │
│         │  roomeq-optimize     │                      │
│         │  (Filter-Generierung)│                      │
│         └──────────────────────┘                      │
│                    │                                   │
│                    ▼                                   │
│         ┌──────────────────────┐                      │
│         │  DSP Filter         │                      │
│         │  (Anwendung)        │                      │
│         └──────────────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 KOMPONENTEN

### **1. Rosa Rauschen Generator**
- **Tool:** `sox` oder `play` (bereits in HiFiBerryOS)
- **Format:** Rosa Rauschen (Pink Noise)
- **Dauer:** Kontinuierlich während Messung
- **Lautstärke:** Anpassbar (-10dB bis -30dB empfohlen)

### **2. Handy-Mikrofon Integration**
- **Option A:** USB-Mikrofon (Handy als USB-Mikrofon)
- **Option B:** Netzwerk-Audio (Handy sendet Audio über Netzwerk)
- **Option C:** Bluetooth-Audio (Handy sendet über Bluetooth)
- **Option D:** WebRTC (Handy sendet über Browser)

### **3. Real Time Analyzer (RTA)**
- **Option A:** RoomEQWizard RTA (Java-basiert, kann auf Pi laufen)
- **Option B:** Python RTA (eigene Implementierung)
- **Option C:** Integration mit HiFiBerryOS `fft-analzye`

### **4. Filter-Generierung**
- **Tool:** `roomeq-optimize` (bereits in HiFiBerryOS)
- **Input:** Frequenzgang-Daten (JSON)
- **Output:** DSP-Filter (EQ-Definitionen)

### **5. DSP-Filter-Anwendung**
- **Tool:** `dsptoolkit` (bereits in HiFiBerryOS)
- **Methode:** Filter auf DSP laden

---

## 📋 IMPLEMENTIERUNGS-PHASEN

### **PHASE 1: Rosa Rauschen Generator**

**Script: `/opt/hifiberry/bin/generate-pink-noise.sh`**
```bash
#!/bin/bash
# Generiert Rosa Rauschen für Raum-Messung

DURATION=${1:-60}  # Sekunden
VOLUME=${2:-"-20"}  # dB

# Rosa Rauschen generieren und abspielen
play -q -n synth $DURATION pinknoise vol $VOLUME
```

---

### **PHASE 2: Handy-Mikrofon Integration**

**Option A: USB-Mikrofon (Empfohlen)**
- Handy als USB-Mikrofon (USB OTG)
- ALSA erkennt als Audio-Input
- Direkte Aufnahme möglich

**Option B: Netzwerk-Audio**
- Handy-App sendet Audio über UDP/TCP
- Server auf HiFiBerryOS empfängt
- Audio-Stream aufnehmen

**Option C: WebRTC**
- Browser-basierte Lösung
- Handy sendet Audio über WebRTC
- Server empfängt und verarbeitet

---

### **PHASE 3: Real Time Analyzer**

**Option A: RoomEQWizard RTA Integration**
- REW RTA auf Pi installieren (Java)
- Audio-Input vom Handy-Mikrofon
- Frequenzgang in Echtzeit messen
- Daten exportieren (JSON/CSV)

**Option B: Python RTA**
- Eigene RTA-Implementierung
- FFT-Analyse in Echtzeit
- Frequenzgang-Daten generieren

**Option C: HiFiBerryOS fft-analzye erweitern**
- Bestehendes Tool erweitern
- Real-Time-Modus hinzufügen
- Kontinuierliche Messung

---

### **PHASE 4: Automatische Filter-Generierung**

**Script: `/opt/hifiberry/bin/auto-room-correction.sh`**
```bash
#!/bin/bash
# Automatische Raumkorrektur

# 1. Rosa Rauschen starten
# 2. Handy-Mikrofon aufnehmen
# 3. RTA misst Frequenzgang
# 4. Daten an roomeq-optimize senden
# 5. Filter generieren
# 6. Filter auf DSP anwenden
```

---

### **PHASE 5: DSP-Filter-Anwendung**

**Script: `/opt/hifiberry/bin/apply-dsp-filters.sh`**
```bash
#!/bin/bash
# Wendet DSP-Filter an

FILTER_FILE=$1

# Filter auf DSP laden
dsptoolkit load-filter "$FILTER_FILE"
```

---

## 🔧 TECHNISCHE DETAILS

### **Rosa Rauschen:**
```bash
# Mit sox/play
play -q -n synth 60 pinknoise vol -20dB

# Kontinuierlich
play -q -n synth pinknoise vol -20dB repeat -
```

### **Handy-Mikrofon (USB):**
```bash
# Mikrofon erkennen
/opt/hifiberry/bin/audio-inputs

# Aufnehmen
arecord -D hw:1,0 -f cd -t wav recording.wav
```

### **RTA Integration:**
```bash
# Frequenzgang messen
/opt/hifiberry/bin/fft-analzye -v 1 -r signal.wav recording.wav

# Daten exportieren
# Format: JSON mit f (Frequenz) und db (Dezibel)
```

### **Filter-Generierung:**
```bash
# JSON-Daten an roomeq-optimize senden
/opt/hifiberry/bin/roomeq-optimize measurement.json

# Output: EQ-Definitionen
# Format: "eq:f0:q:db"
```

### **DSP-Filter-Anwendung:**
```bash
# Filter auf DSP laden
dsptoolkit set-filter "eq:80:0.5:-2.5"
```

---

## 📊 DATEN-FLUSS

```
1. Rosa Rauschen abspielen
   ↓
2. Handy-Mikrofon aufnehmen (am Hörplatz)
   ↓
3. RTA analysiert Audio (FFT)
   ↓
4. Frequenzgang-Daten (JSON)
   ↓
5. roomeq-optimize generiert Filter
   ↓
6. Filter-Definitionen (EQ)
   ↓
7. dsptoolkit wendet Filter an
   ↓
8. DSP aktiviert Filter
```

---

## ✅ VORTEILE

**Automatisch:**
- ✅ Keine manuelle Konfiguration
- ✅ Schnelle Messung
- ✅ Präzise Ergebnisse

**Mit Handy:**
- ✅ Kein zusätzliches Mikrofon nötig
- ✅ Flexibel (jeder Hörplatz)
- ✅ Einfach zu bedienen

**Real Time:**
- ✅ Sofortige Ergebnisse
- ✅ Live-Visualisierung möglich
- ✅ Iterative Optimierung

---

## 📝 NÄCHSTE SCHRITTE

1. **Rosa Rauschen Generator:** Script erstellen
2. **Handy-Mikrofon Integration:** Beste Methode wählen
3. **RTA Integration:** RoomEQWizard oder eigene Lösung
4. **Automatisierung:** Alles zusammenführen
5. **Testing:** Mit echten Messungen testen

---

**Status:** PLAN ERSTELLT  
**Nächster Schritt:** Detaillierte Implementierung

