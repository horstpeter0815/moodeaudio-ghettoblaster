# Flat EQ Preset - Factory Settings Plan

**Datum:** 6. Dezember 2025  
**Ziel:** Flat EQ Preset für Ghetto Crew System basierend auf Frequency Response

---

## 🎯 ANFORDERUNGEN

### **User-Anforderungen:**
1. **Flat EQ Preset:** Gerade Linie für alle Treiber kombiniert
2. **Factory Settings:** Basierend auf Frequency Response Charakteristiken
3. **Graphisch bestimmt:** Basierend auf Frequency Response Kurven
4. **Ein/Aus-Schalter:** Im Web-UI umschaltbar
5. **moOde Preset System:** Nutzung bestehender Templates

---

## 📊 FREQUENCY RESPONSE DATEN

### **Bose 901 Series 6 (Bass - 8x Treiber):**
- **Frequency Response:**
  - ~5-6 dB Anhebung: 130-250 Hz
  - Output-Abfall: -7 dB bei 6.000 Hz
  - Wiederanstieg: 10.000-15.000 Hz
- **EQ-Parameter (Bose 901 Original):**
  - Mid-Bass: ±6 dB bei 225 Hz
  - Mid-Treble: ±6 dB bei 3 kHz
- **Messdaten:** BOSE_901_MEASUREMENTS.md

### **Fostex T90A Super Tweeter (Hochton):**
- **Frequency Response:** (Wird recherchiert)
- **Frequenzbereich:** 5 kHz - 35 kHz
- **Empfindlichkeit:** 106 dB/W(1m)
- **Crossover:** 7 kHz empfohlen

### **Fostex Mitteltön:**
- **Frequency Response:** (Wird recherchiert)
- **Details:** (Wird recherchiert)

---

## 🔧 MOODE AUDIO EQ SYSTEM

### **Bestehende Systeme:**
1. **CamillaDSP:** Erweiterte DSP-Funktionen
2. **ALSA EQ:** Basis Equalizer
3. **Preset System:** Vorhanden in moOde

### **Integration:**
- **Web-UI:** `snd-config.php` / `snd-config.html`
- **Presets:** moOde hat Preset-System
- **Toggle:** Ein/Aus-Schalter implementierbar

---

## 💡 IMPLEMENTIERUNGS-KONZEPT

### **1. Frequency Response Analyse:**
```
Alle Treiber analysieren:
- Bose 901: Bass (20-500 Hz)
- Fostex Mitteltön: Mids (500-5000 Hz)
- Fostex T90A: Highs (5000-35000 Hz)
```

### **2. Inverse Kurve berechnen:**
```
Für Flat Response:
- Messung aller Treiber kombinieren
- Inverse Kurve berechnen (Kompensation)
- Preset-Werte generieren
```

### **3. Preset erstellen:**
```
- CamillaDSP Preset oder ALSA EQ
- Factory Settings: Flat/Line Preset
- Im moOde Preset System speichern
```

### **4. Web-UI Integration:**
```
- Ein/Aus-Schalter in snd-config.html
- PHP Handler in snd-config.php
- Toggle zwischen Flat EQ und Normal
```

---

## 📋 TECHNISCHE DETAILS

### **EQ-Parameter (geschätzt basierend auf Recherche):**

**Bose 901 Kompensation:**
- 130-250 Hz: -5 bis -6 dB (Anhebung ausgleichen)
- 6000 Hz: +7 dB (Abfall ausgleichen)
- 225 Hz: ±6 dB (Mid-Bass)
- 3000 Hz: ±6 dB (Mid-Treble)

**Fostex Kompensation:**
- (Wird basierend auf Frequency Response Daten berechnet)

### **Preset Format:**
```
{
  "name": "Ghetto Crew Flat EQ",
  "type": "camilladsp" oder "alsa-eq",
  "bands": [
    { "freq": 20, "gain": 0 },
    { "freq": 225, "gain": -5 },
    { "freq": 3000, "gain": 0 },
    { "freq": 6000, "gain": 7 },
    { "freq": 20000, "gain": 0 }
  ],
  "enabled": false
}
```

---

## 🎯 NÄCHSTE SCHRITTE

1. ✅ Frequency Response Daten sammeln (alle Treiber)
2. ⏳ Inverse Kurve berechnen
3. ⏳ Preset-Werte generieren
4. ⏳ moOde Integration implementieren
5. ⏳ Web-UI Toggle hinzufügen

---

**Status:** Planung läuft - Frequency Response Daten werden gesammelt

