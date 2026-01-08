# Ghetto Scratch - Phono Cartridge Presets Plan

**Datum:** 6. Dezember 2025  
**Ziel:** MM/MC Cartridge Presets mit Frequency Response Kompensation für Ghetto Scratch

---

## 🎯 KONZEPT

### **User-Anforderung:**
1. **MM/MC Systeme:** Häufigste 50-100 Phono-Cartridge-Systeme recherchieren
2. **Response Curves:** Frequency Response Kurven für alle Systeme finden
3. **Presets:** User kann System auswählen und anwenden
4. **DSP-Kompensation:** Frequency Response Glättung via DSP
5. **REST API:** Für Raspberry Pi Zero 2W

---

## 📊 PHONO-CARTRIDGE-SYSTEME

### **MM (Moving Magnet) Systeme:**

**Top 50-100 häufigste MM Cartridges:**
- (Wird recherchiert)

**Frequency Response Charakteristiken:**
- RIAA Standard
- Cartridge-spezifische Abweichungen
- Loading-Effekte

### **MC (Moving Coil) Systeme:**

**Top 50-100 häufigste MC Cartridges:**
- (Wird recherchiert)

**Frequency Response Charakteristiken:**
- RIAA Standard
- Cartridge-spezifische Abweichungen
- Impedanz-Loading-Effekte

---

## 🔧 IMPLEMENTIERUNGS-KONZEPT

### **1. Preset-Datenbank:**
```
/phono-presets/
  - mm-cartridges.json
  - mc-cartridges.json
  - response-curves/
    - cartridge-1.json
    - cartridge-2.json
    ...
```

### **2. DSP-Kompensation:**
- **CamillaDSP** oder **ALSA EQ**
- Inverse Frequency Response berechnen
- Preset anwenden

### **3. REST API:**
```
GET  /api/phono/cartridges        # Liste aller Cartridges
GET  /api/phono/presets           # Verfügbare Presets
POST /api/phono/apply             # Preset anwenden
GET  /api/phono/current           # Aktuelles Preset
```

### **4. Web-UI:**
- Dropdown: Cartridge auswählen
- Response Curve anzeigen
- Preset anwenden

---

## 📋 PRESET-FORMAT

```json
{
  "id": "ortofon-2m-red",
  "name": "Ortofon 2M Red",
  "type": "MM",
  "manufacturer": "Ortofon",
  "frequency_response": {
    "20": 0.0,
    "50": -2.0,
    "100": 0.0,
    "500": 0.0,
    "1000": 1.0,
    "10000": 2.0,
    "20000": 0.0
  },
  "loading": {
    "impedance": 47000,
    "capacitance": 200
  },
  "compensation_curve": [
    { "freq": 20, "gain": 0.0 },
    { "freq": 50, "gain": 2.0 },
    { "freq": 10000, "gain": -2.0 },
    { "freq": 20000, "gain": 0.0 }
  ]
}
```

---

## 🎯 NÄCHSTE SCHRITTE

1. ⏳ Top 50-100 MM Cartridges recherchieren
2. ⏳ Top 50-100 MC Cartridges recherchieren
3. ⏳ Frequency Response Curves sammeln
4. ⏳ Preset-Datenbank erstellen
5. ⏳ DSP-Kompensation implementieren
6. ⏳ REST API entwickeln

---

**Status:** Konzept erstellt - Recherche startet

