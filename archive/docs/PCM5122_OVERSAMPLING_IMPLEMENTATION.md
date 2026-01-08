# PCM5122 Oversampling Filter Implementation - Ghettoblaster

**Datum:** 6. Dezember 2025  
**Status:** PLANUNG  
**Ziel:** Dropdown-Menü für Oversampling-Algorithmen im moOde Web-Interface

---

## 🎯 ANFORDERUNGEN

**Benutzer-Anfrage:**
- Dropdown-Menü im moOde Web-Interface
- Auswahl von Oversampling-Algorithmen (z.B. "Bezier 1", "Bezier 2")
- Integration in Audio-Menü-Struktur
- Steuerung über ALSA Mixer Controls

---

## 📋 PCM5122 OVERSAMPLING-OPTIONEN

### **Verfügbare ALSA Mixer Controls:**

Der PCM5122 DAC unterstützt verschiedene Oversampling-Filter über ALSA Mixer Controls:

**Typische Controls:**
- `DSP Program` - Filter-Auswahl
- `Filter` - Oversampling-Filter-Typ
- `Oversampling` - Oversampling-Rate

**Mögliche Werte (zu prüfen):**
- Bezier 1
- Bezier 2
- Linear
- Minimum Phase
- Fast Roll-off
- Slow Roll-off

**Hinweis:** Die exakten Control-Namen und Werte müssen auf dem System geprüft werden mit:
```bash
amixer -c 0 controls
amixer -c 0 contents
```

---

## 🔧 IMPLEMENTIERUNGSPLAN

### **1. Backend: ALSA Control Script**

**Datei:** `/usr/local/bin/pcm5122-oversampling.sh`

**Funktionalität:**
- Liest verfügbare Oversampling-Optionen
- Setzt Oversampling-Filter über `amixer`
- Speichert aktuelle Einstellung

**Verwendung:**
```bash
# Liste verfügbare Optionen
pcm5122-oversampling.sh list

# Setze Filter
pcm5122-oversampling.sh set "Bezier 1"
```

---

### **2. Backend: PHP Handler**

**Datei:** `moode-source/www/command/pcm5122-oversampling.php`

**Funktionalität:**
- API-Endpoint für Oversampling-Einstellungen
- Liest aktuelle Einstellung
- Setzt neue Einstellung
- Gibt verfügbare Optionen zurück

---

### **3. Frontend: UI-Integration**

**Datei:** `moode-source/www/snd-config.php`

**Integration:**
- Dropdown-Menü in "ALSA OPTIONS" Sektion
- Nach "Output mode" oder "Max volume"
- AJAX-Update bei Änderung

**HTML-Struktur:**
```html
<div class="form-group">
    <label>Oversampling Filter</label>
    <select id="pcm5122_oversampling" name="pcm5122_oversampling">
        <option value="bezier1">Bezier 1</option>
        <option value="bezier2">Bezier 2</option>
        <option value="linear">Linear</option>
        <option value="minphase">Minimum Phase</option>
    </select>
</div>
```

---

### **4. Database: Einstellung speichern**

**Tabelle:** `cfg_system`

**Parameter:** `pcm5122_oversampling`

**Wert:** Aktuell gewählter Filter (z.B. "bezier1")

---

## 📝 SCHRITTE

### **Schritt 1: ALSA Controls prüfen**

Auf dem System prüfen:
```bash
# Verfügbare Controls
amixer -c 0 controls | grep -i filter
amixer -c 0 controls | grep -i oversampling
amixer -c 0 controls | grep -i dsp

# Control-Werte
amixer -c 0 contents | grep -A 10 "Filter\|Oversampling"
```

### **Schritt 2: Backend-Script erstellen**

- `/usr/local/bin/pcm5122-oversampling.sh`
- Liest/setzt Oversampling-Filter

### **Schritt 3: PHP Handler erstellen**

- `moode-source/www/command/pcm5122-oversampling.php`
- API für Frontend

### **Schritt 4: UI-Integration**

- Dropdown in `snd-config.php`
- AJAX-Handler in JavaScript

### **Schritt 5: Database-Integration**

- Parameter in `cfg_system` speichern
- Beim Boot wiederherstellen

---

## ⚠️ HINWEISE

1. **Control-Namen variieren:** Die exakten ALSA Control-Namen müssen auf dem System geprüft werden
2. **Hardware-spezifisch:** Nur für PCM5122-basierte DACs (HiFiBerry AMP100)
3. **Reboot nicht nötig:** Änderungen sollten sofort wirksam sein
4. **Fallback:** Wenn Controls nicht verfügbar, Dropdown ausblenden

---

## ✅ NÄCHSTE SCHRITTE

1. ALSA Controls auf System prüfen
2. Backend-Script erstellen
3. PHP Handler implementieren
4. UI-Integration durchführen
5. Testen

---

**Status:** BEREIT FÜR IMPLEMENTIERUNG  
**Nächster Schritt:** ALSA Controls prüfen und Backend-Script erstellen

