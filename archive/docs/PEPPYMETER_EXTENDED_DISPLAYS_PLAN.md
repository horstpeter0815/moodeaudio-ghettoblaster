# PeppyMeter Extended Displays - Implementierungsplan

**Datum:** 6. Dezember 2025  
**Status:** PLANUNG  
**Ziel:** Erweiterte Control Displays für PeppyMeter

---

## 🎯 ANFORDERUNGEN

**Benutzer-Anfrage:**
- **Control Display 1:** Umschaltbar zwischen Power Meter und System-Temperatur
  - Temperatur in °C
  - Farbkodierung (rot/grün Bereiche)
- **Control Display 2:** Stream-Informationen
  - Sample Rate (192 kHz, 96 kHz, etc.)
  - Oversampling Rate

---

## 📋 ANALYSE: PEPPYMETER STRUKTUR

### **Aktuelle PeppyMeter-Funktionalität:**
- Zeigt Power Meter (VU-Meter) an
- Liest Audio-Level von ALSA FIFO
- Python-basiert (peppymeter.py)
- Konfiguration in `/etc/peppymeter/config.txt`

### **Erforderliche Erweiterungen:**
1. **Temperatur-Display:**
   - Liest CPU-Temperatur von `/sys/class/thermal/thermal_zone0/temp`
   - Zeigt in °C an
   - Farbkodierung: Grün (< 60°C), Gelb (60-70°C), Rot (> 70°C)

2. **Stream-Info-Display:**
   - Liest Sample Rate von MPD oder ALSA
   - Zeigt Format an (z.B. "192 kHz / 32-bit")
   - Zeigt Oversampling-Rate an

3. **Umschalt-Logik:**
   - Touchscreen-Geste oder Button
   - Oder automatisches Umschalten nach Zeitintervall

---

## 🔧 IMPLEMENTIERUNGSPLAN

### **Option 1: PeppyMeter Python-Code erweitern**

**Vorteile:**
- Direkte Integration
- Vollständige Kontrolle

**Nachteile:**
- PeppyMeter-Code muss modifiziert werden
- Komplexer

### **Option 2: Separates Overlay-System**

**Vorteile:**
- PeppyMeter bleibt unverändert
- Flexibler
- Einfacher zu warten

**Nachteile:**
- Zusätzliche Komponente nötig

### **Option 3: Hybrid-Ansatz (EMPFOHLEN)**

**Konzept:**
- PeppyMeter läuft normal (Power Meter)
- Separates Python-Script überlagert Display
- Umschaltung über Touchscreen-Geste oder Button

---

## 📝 DETAILLIERTER PLAN

### **Phase 1: Daten-Sampler Script**

**Datei:** `/usr/local/bin/peppymeter-data-sampler.sh`

**Funktionalität:**
- Liest CPU-Temperatur
- Liest Stream-Info (Sample Rate) von MPD
- Schreibt in Shared Memory oder FIFO

**Output-Format:**
```json
{
  "temperature": 45.2,
  "temperature_color": "green",
  "sample_rate": 192000,
  "sample_rate_display": "192 kHz",
  "bit_depth": 32,
  "format": "192 kHz / 32-bit"
}
```

---

### **Phase 2: Display-Overlay Script**

**Datei:** `/usr/local/bin/peppymeter-overlay.py`

**Funktionalität:**
- Zeigt Overlay über PeppyMeter
- Zeigt Temperatur oder Stream-Info
- Umschaltung über Touchscreen oder Timer

**Features:**
- Transparentes Overlay
- Farbkodierte Temperatur
- Stream-Info-Anzeige
- Touchscreen-Geste zum Umschalten

---

### **Phase 3: UI-Integration**

**Datei:** `moode-source/www/peppy-config.php`

**Features:**
- Dropdown: Control Display 1 Modus (Power Meter / Temperatur)
- Dropdown: Control Display 2 Modus (Power Meter / Stream Info)
- Umschalt-Intervall (automatisch)
- Touchscreen-Geste aktivieren/deaktivieren

---

## 🎨 DISPLAY-DESIGN

### **Temperatur-Display:**
```
┌─────────────────┐
│  CPU Temp       │
│                 │
│   45.2°C        │  (grün)
│                 │
│  [████░░░░]     │  (Balken)
└─────────────────┘
```

**Farbkodierung:**
- Grün: < 60°C
- Gelb: 60-70°C
- Rot: > 70°C

### **Stream-Info-Display:**
```
┌─────────────────┐
│  Stream Info    │
│                 │
│  192 kHz        │
│  32-bit         │
│                 │
│  Oversampling:  │
│  4x             │
└─────────────────┘
```

---

## 🔄 UMSCHALT-LOGIK

### **Option A: Automatisches Umschalten**
- Alle X Sekunden zwischen Power Meter und Info wechseln
- Konfigurierbar im UI

### **Option B: Touchscreen-Geste**
- Tap auf Display 1 → Umschalten Display 1
- Tap auf Display 2 → Umschalten Display 2

### **Option C: Beides**
- Automatisches Umschalten + Touchscreen-Geste möglich

---

## 📋 TECHNISCHE DETAILS

### **Temperatur auslesen:**
```bash
cat /sys/class/thermal/thermal_zone0/temp | awk '{printf "%.1f", $1/1000}'
```

### **Sample Rate aus MPD:**
```bash
mpc status -f "%samplerate%"
# Oder
mpc stats | grep "Sample rate"
```

### **Sample Rate aus ALSA:**
```bash
cat /proc/asound/card0/pcm0p/sub0/hw_params | grep rate
```

---

## ⚠️ HINWEISE

1. **PeppyMeter-Integration:** Muss mit bestehendem PeppyMeter kompatibel sein
2. **Performance:** Overlay sollte nicht zu viel CPU verbrauchen
3. **Touchscreen:** Geste muss einfach sein (z.B. Tap)
4. **Farben:** Sollten gut lesbar sein auf dem Display

---

## ✅ NÄCHSTE SCHRITTE

1. PeppyMeter-Code analysieren (wo werden Displays gerendert?)
2. Overlay-System implementieren
3. Daten-Sampler erstellen
4. UI-Integration
5. Testen

---

**Status:** BEREIT FÜR IMPLEMENTIERUNG  
**Nächster Schritt:** PeppyMeter-Code analysieren

