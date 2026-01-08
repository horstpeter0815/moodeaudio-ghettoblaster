# ROOMEQWIZARD RTA INTEGRATION - PLAN

**Datum:** 2. Dezember 2025  
**Status:** PLAN  
**Zweck:** RoomEQWizard Real Time Analyzer Integration

---

## 🎯 ROOMEQWIZARD RTA

**Was ist RoomEQWizard RTA:**
- ✅ Real Time Analyzer für Frequenzgang-Messung
- ✅ Java-basiert (kann auf Pi laufen)
- ✅ Unterstützt verschiedene Mikrofone
- ✅ Exportiert Daten (JSON/CSV)
- ✅ Open Source

**Integration:**
- ✅ RTA auf HiFiBerryOS installieren
- ✅ Audio-Input vom Handy-Mikrofon
- ✅ Frequenzgang in Echtzeit messen
- ✅ Daten exportieren für roomeq-optimize

---

## 📋 INTEGRATIONS-OPTIONEN

### **Option 1: REW RTA direkt auf Pi**
- REW installieren (Java erforderlich)
- Audio-Input konfigurieren
- RTA starten
- Daten exportieren

**Vorteile:**
- ✅ Vollständige REW-Funktionalität
- ✅ Professionelle Analyse

**Nachteile:**
- ⚠️ Java auf Pi (Ressourcen)
- ⚠️ Komplexe Installation

---

### **Option 2: REW RTA auf Handy, Daten senden**
- REW App auf Handy
- RTA auf Handy laufen lassen
- Daten über Netzwerk senden
- HiFiBerryOS empfängt und verarbeitet

**Vorteile:**
- ✅ Handy hat mehr Power
- ✅ Einfache Bedienung
- ✅ Keine Java auf Pi nötig

**Nachteile:**
- ⚠️ Netzwerk-Integration nötig
- ⚠️ App-Entwicklung

---

### **Option 3: Python RTA (eigene Implementierung)**
- Python-basierter RTA
- FFT-Analyse in Echtzeit
- Direkt in HiFiBerryOS integriert

**Vorteile:**
- ✅ Vollständige Kontrolle
- ✅ Leichtgewichtig
- ✅ Direkte Integration

**Nachteile:**
- ⚠️ Eigene Entwicklung nötig
- ⚠️ Weniger Features als REW

---

## 🔧 EMPFOHLENE LÖSUNG

**Hybrid-Ansatz:**
1. **Rosa Rauschen:** Auf HiFiBerryOS abspielen
2. **Handy-Mikrofon:** USB oder Netzwerk
3. **RTA:** Python-basiert auf HiFiBerryOS (leichtgewichtig)
4. **Filter-Generierung:** roomeq-optimize (bereits vorhanden)
5. **DSP-Anwendung:** dsptoolkit (bereits vorhanden)

**Warum:**
- ✅ Nutzt vorhandene HiFiBerryOS Tools
- ✅ Keine Java-Abhängigkeit
- ✅ Leichtgewichtig
- ✅ Vollständig integriert

---

## 📊 DATEN-FORMAT

**Input für roomeq-optimize:**
```json
{
  "measurement": {
    "f": [20, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240, 20480],
    "db": [-25, -15, -5, 2.4, -5, 2.1, 0.5, 4.6, -2.1, -1.3, -7.0]
  },
  "curve": "flat",
  "optimizer": "smooth",
  "filtercount": 10,
  "samplerate": 48000
}
```

**Output von roomeq-optimize:**
```json
{
  "eqdefinitions": [
    "hp:80.0:0.5",
    "eq:2560:4.999:-4.548",
    "eq:80:0.972:-2.950"
  ]
}
```

---

## 🔧 IMPLEMENTIERUNG

**Script-Architektur:**
1. `generate-pink-noise.sh` - Rosa Rauschen
2. `capture-phone-mic.sh` - Handy-Mikrofon aufnehmen
3. `rta-analyze.sh` - Real Time Analyzer
4. `generate-filters.sh` - Filter generieren
5. `apply-dsp-filters.sh` - Filter anwenden
6. `auto-room-correction.sh` - Alles zusammenführen

---

**Status:** PLAN ERSTELLT  
**Nächster Schritt:** Script-Implementierung

