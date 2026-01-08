# DSP Projekt: Bose Wave Radio 3rd Generation

**Datum:** 30. November 2025  
**Ziel:** DSP für Bose Wave Radio 3rd Generation programmieren

---

## 🎯 PROJEKT-ZIEL

Entwicklung eines Digital Signal Processors (DSP) für das Bose Wave Radio der 3. Generation, um:
- Audio-Qualität zu verbessern
- Equalizer-Einstellungen anzupassen
- Raumkorrektur durchzuführen
- Custom Audio-Effekte hinzuzufügen

---

## 📊 BOSE WAVE RADIO 3RD GEN - SPEZIFIKATIONEN

### Hardware
- **Lautsprecher:** 2x Full-Range + Passive Radiator
- **Verstärker:** Integriert
- **Audio-Input:** Analog (3.5mm), Digital (Optical)
- **Frequenzgang:** ~50Hz - 20kHz
- **Leistung:** ~200W Peak

### Audio-Charakteristik
- **Bass:** Stark, aber kann überwältigend sein
- **Mitten:** Ausgeglichen
- **Höhen:** Etwas gedämpft

---

## 🛠️ IMPLEMENTIERUNGS-OPTIONEN

### Option 1: HiFiBerry DSP Add-on

**Vorteile:**
- Hardware-basiert (niedrige Latenz)
- Integriert mit HiFiBerry AMP100
- Professionelle Lösung

**Nachteile:**
- Zusätzliche Hardware nötig
- Kosten

### Option 2: Software-DSP (CamillaDSP)

**Vorteile:**
- Keine zusätzliche Hardware
- Sehr flexibel
- Open Source

**Nachteile:**
- Höhere Latenz
- CPU-Last

### Option 3: MPD Plugins

**Vorteile:**
- Integriert mit MPD
- Einfach zu konfigurieren

**Nachteile:**
- Begrenzte Funktionalität

---

## 📋 RESEARCH-BEREICHE

### 1. Bose Wave Radio Charakteristik
- Frequenzgang messen
- Impulsantwort analysieren
- Raumkorrektur-Parameter bestimmen

### 2. DSP-Algorithmen
- Equalizer (Parametric, Graphic)
- Room Correction
- Bass Management
- Dynamic Range Compression

### 3. Integration
- ALSA Integration
- MPD Integration
- Moode Audio Integration

---

## 🔬 TECHNISCHE ANFORDERUNGEN

### Hardware
- ✅ Raspberry Pi 5 (vorhanden)
- ✅ HiFiBerry AMP100 (in Arbeit)
- ⏳ HiFiBerry DSP Add-on (optional)
- ⏳ Mess-Mikrofon (für Room Correction)

### Software
- ⏳ CamillaDSP oder ähnlich
- ⏳ Room Correction Software
- ⏳ Measurement Tools

---

## 📝 IMPLEMENTIERUNGS-PLAN

### Phase 1: Research & Analyse
1. Bose Wave Radio Charakteristik messen
2. DSP-Software auswählen
3. Integration planen

### Phase 2: Basis-Implementation
1. DSP-Software installieren
2. Basis-Equalizer konfigurieren
3. Testen

### Phase 3: Erweiterte Features
1. Room Correction implementieren
2. Custom Presets erstellen
3. Integration mit Moode Audio

### Phase 4: Optimierung
1. Latenz optimieren
2. CPU-Last reduzieren
3. Audio-Qualität verbessern

---

## 🔗 REFERENZEN

- [CamillaDSP](https://github.com/HEnquist/camilladsp)
- [HiFiBerry DSP](https://www.hifiberry.com/shop/boards/dsp-add-on/)
- [Room Correction](https://www.diyaudio.com/community/threads/room-correction-dsp.123456/)
- [Bose Wave Radio Specs](https://www.bose.com/...)

---

## 📅 ZEITPLAN

- **Phase 1:** Nach Audio-Fix (HiFiBerry AMP100)
- **Phase 2:** Nach PeppyMeter Setup
- **Phase 3:** Nach Basis-Implementation
- **Phase 4:** Kontinuierlich

---

**Status:** Planung - Wartet auf Audio-Fix und PeppyMeter
