# BOSE WAVE KANALAUFTEILUNG - RECHERCHE

**Datum:** 03.12.2025  
**Zweck:** Recherche über Bose Wave Kanalaufteilung (Bass/Mitten)  
**Status:** ✅ Recherche abgeschlossen

---

## 🔍 WICHTIGE ERKENNTNISSE

### **1. BOSE WAVE HAT ZWEI TREIBER:**

**Hardware-Konfiguration:**
- **2x 2,5-Zoll-Treiber**
- **Treiber 1:** Mit Waveguide verbunden → **BASS** (70-300 Hz)
- **Treiber 2:** Direkt → **MITTEN/HÖHEN** (ab ~300 Hz)

**Quelle:** [Autospeed.com - Bose Wave Radio Analysis](https://www.autospeed.com/cms/a_1372/article)

**Bedeutung:**
- ✅ **Ein Kanal für Bass** (via Waveguide)
- ✅ **Ein Kanal für Mitten/Höhen** (direkt)

---

### **2. HIFIBERRYOS KANAL-ROUTING MÖGLICHKEITEN:**

**Im Projekt gefunden:**

#### **A. `speaker-role` Script:**
```bash
/opt/hifiberry/bin/speaker-role
```

**Unterstützte Modi:**
- `mono` - Beide Kanäle gemischt (50/50)
- `stereo` - Standard Stereo (L→L, R→R)
- `left` - Nur linker Kanal
- `right` - Nur rechter Kanal
- `swap` - Kanäle getauscht

**Routing-Tabelle (`ttable`):**
```ini
ttable.0.0 1  # Input 0 → Output 0
ttable.1.1 1  # Input 1 → Output 1
ttable.0.1 0  # Input 0 → Output 1 (kein Crossfeed)
ttable.1.0 0  # Input 1 → Output 0 (kein Crossfeed)
```

**Quelle:** `hifiberry-os/buildroot/package/hifiberry-tools/speaker-role`

#### **B. ALSA Routing Table (`asound.conf`):**
```ini
pcm.ttable {
  type route
  ttable.0.0 1  # L → L
  ttable.1.1 1  # R → R
  ttable.0.1 0  # L → R (aus)
  ttable.1.0 0  # R → L (aus)
  slave.pcm "hifiberry"
}
```

**Quelle:** `hifiberry-os/buildroot/package/hifiberry-tools/conf/asound.conf.exclusive`

#### **C. DSP Channel Selection (XML Profile):**
```xml
<metadata type="channelSelectARegister" channels="left,right,mono,side" ...>
<metadata type="channelSelectBRegister" channels="left,right,mono,side" ...>
<metadata type="channelSelectCRegister" channels="left,right,mono,side" ...>
<metadata type="channelSelectDRegister" channels="left,right,mono,side" ...>
```

**Quelle:** `hifiberry-os/buildroot/package/dspprofiles/dspdac-10.xml`

---

## 💡 MÖGLICHE IMPLEMENTIERUNG

### **Ansatz 1: Mono-Modus mit DSP-Filterung**

**Konzept:**
- Beide Kanäle zu Mono mischen
- DSP-Filterung auf beide Kanäle anwenden
- **Problem:** Keine separate Bass/Mitten-Trennung

**Konfiguration:**
```bash
speaker-role mono
dsptoolkit tone-control ls 200Hz 2.5db  # Bass für beide
dsptoolkit tone-control hs 5000Hz 2.5db  # Treble für beide
```

---

### **Ansatz 2: Stereo mit Kanal-spezifischer Filterung**

**Konzept:**
- **Kanal 0 (Links):** Bass-Filter (Low Shelf)
- **Kanal 1 (Rechts):** Mitten/Höhen-Filter (High Shelf)
- **Problem:** HiFiBerry DSP unterstützt möglicherweise keine Kanal-spezifische Filterung

**Konfiguration:**
```bash
# Kanal 0: Bass
dsptoolkit tone-control ls 200Hz 2.5db --channel 0

# Kanal 1: Mitten/Höhen
dsptoolkit tone-control hs 5000Hz 2.5db --channel 1
```

**⚠️ Prüfen:** Ob `dsptoolkit` Kanal-spezifische Filterung unterstützt!

---

### **Ansatz 3: ALSA Routing + DSP**

**Konzept:**
- ALSA Routing-Tabelle anpassen
- Bass-Signal auf Kanal 0
- Mitten/Höhen-Signal auf Kanal 1
- DSP-Filterung pro Kanal

**Konfiguration (`asound.conf`):**
```ini
pcm.ttable {
  type route
  # Bass auf Kanal 0
  ttable.0.0 1  # L → L (Bass)
  ttable.1.0 1  # R → L (Bass gemischt)
  # Mitten/Höhen auf Kanal 1
  ttable.0.1 1  # L → R (Mitten/Höhen)
  ttable.1.1 1  # R → R (Mitten/Höhen)
  slave.pcm "hifiberry"
}
```

**Problem:** Erfordert Frequenzweiche vor Routing!

---

### **Ansatz 4: DSP IIR Filter mit Frequenzweiche**

**Konzept:**
- IIR Filter für Frequenzweiche
- Bass-Signal auf Kanal 0
- Mitten/Höhen-Signal auf Kanal 1
- Separate DSP-Filterung

**Konfiguration:**
```bash
# Frequenzweiche: 300 Hz
dsptoolkit apply-iir-filters lowpass 300Hz --output 0  # Bass → Kanal 0
dsptoolkit apply-iir-filters highpass 300Hz --output 1  # Mitten/Höhen → Kanal 1

# DSP-Filterung
dsptoolkit tone-control ls 200Hz 2.5db --channel 0  # Bass
dsptoolkit tone-control hs 5000Hz 2.5db --channel 1  # Treble
```

**⚠️ Prüfen:** Ob `dsptoolkit` Frequenzweichen und Kanal-spezifische Filterung unterstützt!

---

## ⚠️ KRITISCHE FRAGEN

### **1. Unterstützt HiFiBerry DSP Kanal-spezifische Filterung?**
- ❓ Kann `dsptoolkit` Filter pro Kanal setzen?
- ❓ Gibt es `--channel` Parameter?

### **2. Unterstützt HiFiBerry DSP Frequenzweichen?**
- ❓ Kann `dsptoolkit` Lowpass/Highpass Filter setzen?
- ❓ Kann Output-Kanal für Filter gewählt werden?

### **3. Wie funktioniert Bose Wave intern?**
- ❓ Hardware-Frequenzweiche?
- ❓ DSP-Frequenzweiche?
- ❓ Beide Treiber bekommen volles Signal?

---

## 📊 ZUSAMMENFASSUNG

### **Was wir WISSEN:**
- ✅ Bose Wave hat 2 Treiber (Bass + Mitten/Höhen)
- ✅ HiFiBerryOS hat `speaker-role` für Kanal-Routing
- ✅ HiFiBerryOS hat ALSA Routing-Tabelle (`ttable`)
- ✅ HiFiBerryOS hat DSP Channel Selection

### **Was wir NICHT WISSEN:**
- ❓ Unterstützt `dsptoolkit` Kanal-spezifische Filterung?
- ❓ Unterstützt `dsptoolkit` Frequenzweichen?
- ❓ Wie funktioniert Bose Wave intern (Hardware/DSP)?

### **Was wir PRÜFEN MÜSSEN:**
- ⏳ `dsptoolkit` Dokumentation/Help
- ⏳ `dsptoolkit` verfügbare Parameter
- ⏳ HiFiBerry DSP Fähigkeiten

---

## 🎯 NÄCHSTE SCHRITTE

1. **Prüfe `dsptoolkit` Dokumentation:**
   ```bash
   dsptoolkit --help
   dsptoolkit tone-control --help
   dsptoolkit apply-iir-filters --help
   ```

2. **Prüfe verfügbare DSP-Funktionen:**
   ```bash
   dsptoolkit list-filters
   dsptoolkit list-channels
   ```

3. **Teste Kanal-spezifische Filterung:**
   ```bash
   dsptoolkit tone-control ls 200Hz 2.5db --channel 0
   dsptoolkit tone-control hs 5000Hz 2.5db --channel 1
   ```

4. **Falls nicht unterstützt:**
   - Mono-Modus mit DSP-Filterung (beide Kanäle gleich)
   - Oder: ALSA Routing + Software-Frequenzweiche

---

## 📚 QUELLEN

1. [Autospeed - Bose Wave Radio Analysis](https://www.autospeed.com/cms/a_1372/article)
2. `hifiberry-os/buildroot/package/hifiberry-tools/speaker-role`
3. `hifiberry-os/buildroot/package/hifiberry-tools/conf/asound.conf.exclusive`
4. `hifiberry-os/buildroot/package/dspprofiles/dspdac-10.xml`

---

**Status:** ✅ Recherche abgeschlossen  
**Nächster Schritt:** `dsptoolkit` Dokumentation prüfen

