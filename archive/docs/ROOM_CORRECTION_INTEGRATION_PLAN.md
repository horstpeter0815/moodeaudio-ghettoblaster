# ROOM CORRECTION INTEGRATION - KOMPLETTER PLAN

**Datum:** 2. Dezember 2025  
**Status:** PLAN  
**Zweck:** Integration in HiFiBerryOS für automatische Raumkorrektur

---

## 🎯 ZIEL

**Automatische Raumkorrektur:**
1. Rosa Rauschen abspielen
2. Handy-Mikrofon am Hörplatz aufnehmen
3. Real Time Analyzer misst Frequenzgang
4. Automatisch DSP-Filter generieren
5. Filter auf HiFiBerryOS DSP anwenden

---

## 📋 VORHANDENE HIFIBERRYOS TOOLS

### **Bereits vorhanden:**
- ✅ `room-measure` - Raum-Messung
- ✅ `roomeq-optimize` - Filter-Optimierung
- ✅ `roomeq-preset` - Target Curves
- ✅ `fft-analzye` - FFT-Analyse
- ✅ `dsptoolkit` - DSP-Management
- ✅ `audio-inputs` - Mikrofon-Erkennung

### **Zu integrieren:**
- ⏳ Rosa Rauschen Generator
- ⏳ Handy-Mikrofon Integration
- ⏳ Real Time Analyzer (RTA)
- ⏳ Automatische Filter-Anwendung

---

## 🔧 IMPLEMENTIERUNGS-STRATEGIE

### **PHASE 1: Basis-Script (Mac)**
- ✅ Rosa Rauschen Generator
- ✅ Handy-Mikrofon Aufnahme
- ✅ FFT-Analyse
- ✅ Filter-Generierung
- ✅ Script-Test

### **PHASE 2: HiFiBerryOS Integration**
- ⏳ Script auf HiFiBerryOS deployen
- ⏳ Service erstellen
- ⏳ Web-UI Integration (optional)

### **PHASE 3: Real Time Analyzer**
- ⏳ RTA Integration
- ⏳ Live-Visualisierung
- ⏳ Iterative Optimierung

### **PHASE 4: Automatisierung**
- ⏳ Vollautomatischer Ablauf
- ⏳ Ein-Klick-Messung
- ⏳ Automatische Filter-Anwendung

---

## 📊 HANDY-MIKROFON OPTIONEN

### **Option 1: USB-Mikrofon (Empfohlen)**
- Handy als USB-Mikrofon (USB OTG)
- ALSA erkennt automatisch
- Direkte Aufnahme mit `arecord`

**Vorteile:**
- ✅ Einfach
- ✅ Gute Qualität
- ✅ Niedrige Latenz

---

### **Option 2: Netzwerk-Audio**
- Handy-App sendet Audio über UDP/TCP
- Server auf HiFiBerryOS empfängt
- Audio-Stream aufnehmen

**Vorteile:**
- ✅ Flexibel
- ✅ Kein Kabel nötig

**Nachteile:**
- ⚠️ App-Entwicklung nötig
- ⚠️ Netzwerk-Latenz

---

### **Option 3: WebRTC**
- Browser-basierte Lösung
- Handy sendet Audio über WebRTC
- Server empfängt und verarbeitet

**Vorteile:**
- ✅ Keine App nötig
- ✅ Browser-basiert

**Nachteile:**
- ⚠️ Komplexere Integration
- ⚠️ WebRTC-Server nötig

---

## 🔧 ROOMEQWIZARD RTA INTEGRATION

### **Option 1: REW RTA auf Pi**
- REW installieren (Java)
- Audio-Input konfigurieren
- RTA starten

**Nachteile:**
- ⚠️ Java auf Pi (Ressourcen)
- ⚠️ Komplex

---

### **Option 2: Python RTA (Empfohlen)**
- Python-basierter RTA
- FFT-Analyse in Echtzeit
- Leichtgewichtig

**Vorteile:**
- ✅ Leichtgewichtig
- ✅ Vollständige Kontrolle
- ✅ Direkte Integration

---

### **Option 3: HiFiBerryOS fft-analzye erweitern**
- Bestehendes Tool erweitern
- Real-Time-Modus
- Kontinuierliche Messung

**Vorteile:**
- ✅ Nutzt vorhandene Tools
- ✅ Konsistent mit HiFiBerryOS

---

## 📋 SCRIPT-ARCHITEKTUR

### **Haupt-Script: `auto-room-correction.sh`**
```bash
1. Audio-Inputs prüfen (Handy-Mikrofon)
2. Rosa Rauschen starten
3. Handy-Mikrofon aufnehmen
4. FFT-Analyse (RTA)
5. Daten zu JSON konvertieren
6. roomeq-optimize (Filter generieren)
7. Filter auf DSP anwenden
```

### **Unterstützende Scripts:**
- `generate-pink-noise.sh` - Rosa Rauschen
- `capture-phone-mic.sh` - Handy-Mikrofon
- `rta-analyze.sh` - Real Time Analyzer
- `apply-dsp-filters.sh` - Filter anwenden

---

## ✅ INTEGRATION IN HIFIBERRYOS

### **Service erstellen:**
```ini
[Unit]
Description=Automatic Room Correction
After=sound.target

[Service]
Type=oneshot
ExecStart=/opt/hifiberry/bin/auto-room-correction.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### **Web-UI Integration (optional):**
- Button in HiFiBerryOS Web-UI
- Startet automatische Messung
- Zeigt Ergebnisse
- Filter anwenden/verwerfen

---

## 📊 DATEN-FLUSS

```
Rosa Rauschen
    ↓
Raum (Akustik)
    ↓
Handy-Mikrofon (Hörplatz)
    ↓
Audio-Aufnahme
    ↓
FFT-Analyse (RTA)
    ↓
Frequenzgang-Daten (JSON)
    ↓
roomeq-optimize
    ↓
Filter-Definitionen
    ↓
dsptoolkit
    ↓
DSP-Filter aktiv
```

---

## ✅ VORTEILE

**Automatisch:**
- ✅ Keine manuelle Konfiguration
- ✅ Schnelle Messung (60 Sekunden)
- ✅ Präzise Ergebnisse

**Mit Handy:**
- ✅ Kein zusätzliches Mikrofon
- ✅ Flexibel (jeder Hörplatz)
- ✅ Einfach zu bedienen

**Integration:**
- ✅ Nutzt vorhandene HiFiBerryOS Tools
- ✅ Vollständig integriert
- ✅ Service-basiert

---

## 📝 NÄCHSTE SCHRITTE

1. **Script testen:** Auf Mac entwickeln
2. **HiFiBerryOS deployen:** Script auf Pi 4 deployen
3. **Service erstellen:** systemd Service
4. **Testing:** Mit echten Messungen
5. **Optimierung:** Iterative Verbesserung

---

**Status:** PLAN ERSTELLT  
**Script:** `auto-room-correction-script.sh`  
**Nächster Schritt:** Script testen und optimieren

