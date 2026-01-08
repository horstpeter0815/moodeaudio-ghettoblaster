# BOSE WAVE REW-MESSUNG PLAN

**Datum:** 03.12.2025  
**Zweck:** Vorbereitung für Room EQ Wizard Messung des originalen Bose Wave Radios  
**Status:** ✅ Plan fertig - Messung später durchführen

---

## 🎯 ZIEL DER MESSUNG

**Hauptziel:**
- Frequenzgang des originalen Bose Wave Radios messen
- DSP-Einstellungen ableiten für HiFiBerry AMP100
- Exakte Nachbildung des Bose Wave Klangs

**Messungen:**
1. Frequenzgang (Frequency Response)
2. Impulsantwort (Impulse Response)
3. THD (Total Harmonic Distortion)
4. Phase Response

---

## 📋 VORAUSSETZUNGEN

### **Hardware:**
- ✅ Originales Bose Wave Radio
- ⏳ Messmikrofon (z.B. UMIK-1, Behringer ECM8000, Dayton Audio EMM-6)
- ⏳ Audio-Interface (falls Mikrofon nicht USB)
- ✅ Computer/Laptop für REW
- ✅ Kabel für Audio-Output (3.5mm, RCA, etc.)

### **Software:**
- ⏳ Room EQ Wizard (REW) - [Download](https://www.roomeqwizard.com/)
- ⏳ Java Runtime Environment (für REW)

---

## 🔧 MESSUNG VORBEREITUNG

### **1. REW Installation:**

**Download:**
- [REW Website](https://www.roomeqwizard.com/)
- Version: 5.20 oder neuer (empfohlen)

**Installation:**
1. Java installieren (falls nicht vorhanden)
2. REW herunterladen
3. REW starten

---

### **2. Messmikrofon Kalibrierung:**

**WICHTIG:** Messmikrofon MUSS kalibriert sein!

**Option A: UMIK-1 (USB):**
- ✅ Kommt mit Kalibrierungsdatei
- ✅ Einfachste Lösung
- ✅ Direkt USB-Anschluss

**Option B: Andere Mikrofone:**
- ⚠️ Benötigen Kalibrierungsdatei vom Hersteller
- ⚠️ Oder: Externe Kalibrierung erforderlich

**Kalibrierungsdatei in REW laden:**
1. REW → Preferences → Calibration Files
2. Kalibrierungsdatei auswählen
3. Apply

---

### **3. Audio-Setup:**

**Bose Wave → Computer:**
- **Option 1:** 3.5mm Kabel (Bose Wave Line-Out → Computer Line-In)
- **Option 2:** USB-Audio-Interface (falls verfügbar)
- **Option 3:** Bluetooth (falls Bose Wave unterstützt)

**Computer → Messmikrofon:**
- USB-Mikrofon: Direkt USB
- XLR-Mikrofon: Audio-Interface erforderlich

---

### **4. REW Konfiguration:**

**Audio Settings:**
1. REW → Preferences → Soundcard
2. Input Device: Messmikrofon auswählen
3. Output Device: Computer Audio-Out (für Sweep)
4. Sample Rate: 48 kHz (empfohlen)
5. Buffer Size: 512 Samples (Standard)

**Measurement Settings:**
1. REW → Preferences → Measurement
2. Sweep Length: 256k (Standard)
3. Sweep Range: 20 Hz - 20 kHz
4. Output Level: -12 dB (Sicherheitsmarge)

---

## 📐 MESSUNG DURCHFÜHRUNG

### **1. Raum-Vorbereitung:**

**WICHTIG:** Messung in typischem Hörraum!

**Bedingungen:**
- ✅ Raum wie normalerweise verwendet
- ✅ Bose Wave in normaler Position
- ✅ Keine Störgeräusche
- ✅ Raumtemperatur normal (20-25°C)

**Mikrofon-Position:**
- **Abstand:** 1 Meter vom Bose Wave (Standard)
- **Höhe:** Auf Höhe der Hörposition (z.B. 1,2-1,5m)
- **Winkel:** Direkt auf Bose Wave gerichtet
- **Alternative:** Mehrere Positionen messen (Durchschnitt)

---

### **2. Referenz-Messung (Bose Wave):**

**Schritte:**
1. REW öffnen
2. "Measure" Button klicken
3. "Start Measurement" wählen
4. **WICHTIG:** Bose Wave auf Referenz-Lautstärke (z.B. 50%)
5. Sweep abspielen (automatisch)
6. Messung speichern als: `Bose_Wave_Original_1m.spl`

**Wiederholung:**
- 3-5 Messungen durchführen
- Durchschnitt bilden (REW kann das automatisch)

---

### **3. Vergleichs-Messung (HiFiBerry):**

**Nach DSP-Einstellung:**
1. HiFiBerry mit aktuellen DSP-Einstellungen messen
2. Gleiche Position, gleiche Lautstärke
3. Speichern als: `HiFiBerry_Current_1m.spl`

**Vergleich:**
- REW → "All SPL" → Beide Kurven überlagern
- Unterschiede identifizieren

---

## 📊 MESSERGEBNISSE INTERPRETIEREN

### **1. Frequenzgang-Analyse:**

**Was zu prüfen:**
- **Bass-Bereich (20-300 Hz):** Anhebung/Absenkung?
- **Mitten-Bereich (300-3000 Hz):** Flach oder angepasst?
- **Höhen-Bereich (3000-20000 Hz):** Anhebung/Absenkung?

**Beispiel:**
```
20-100 Hz:  +3 dB (Bass angehoben)
100-300 Hz: +2 dB (Bass warm)
300-1000 Hz: 0 dB (Mitten flach)
1000-5000 Hz: +1 dB (Präsenz)
5000-20000 Hz: +2 dB (Höhen klar)
```

---

### **2. EQ-Einstellungen ableiten:**

**Methode:**
1. REW → "EQ" Tab
2. Target Curve wählen (z.B. "Flat" oder "Harman")
3. "Match Response to Target" klicken
4. REW berechnet notwendige EQ-Einstellungen

**Export:**
- REW → "Export" → "Filter Settings"
- Format: Parametric EQ (für DSP)

---

### **3. DSP-Parameter berechnen:**

**Für HiFiBerry DSP:**

**Tone Control:**
- **Low Shelf (Bass):** Frequenz + dB aus REW
- **High Shelf (Treble):** Frequenz + dB aus REW

**IIR Filter (falls verfügbar):**
- Parametric EQ aus REW exportieren
- In DSP-Format konvertieren

---

## 🔧 DSP-EINSTELLUNGEN UMSETZEN

### **1. Tone Control (Einfach):**

**Aus REW-Messung:**
```
Bass: +3 dB bei 200 Hz
Treble: +2 dB bei 5000 Hz
```

**HiFiBerry DSP:**
```bash
dsptoolkit tone-control ls 200Hz 3db
dsptoolkit tone-control hs 5000Hz 2db
dsptoolkit store-settings
```

---

### **2. Parametric EQ (Erweitert):**

**Aus REW exportiert:**
```
Filter 1: PEQ, 80 Hz, Q=1.0, +3 dB
Filter 2: PEQ, 200 Hz, Q=0.7, +2 dB
Filter 3: PEQ, 5000 Hz, Q=1.0, +2 dB
```

**HiFiBerry DSP (falls unterstützt):**
```bash
dsptoolkit apply-iir-filters peq 80Hz 1.0 3db
dsptoolkit apply-iir-filters peq 200Hz 0.7 2db
dsptoolkit apply-iir-filters peq 5000Hz 1.0 2db
dsptoolkit store-settings
```

**⚠️ Prüfen:** Ob `dsptoolkit` Parametric EQ unterstützt!

---

### **3. Kanal-spezifische Einstellungen:**

**Falls Bose Wave Kanal-Trennung hat:**
- **Kanal 0 (Bass):** Low Shelf Filter
- **Kanal 1 (Mitten/Höhen):** High Shelf Filter

**HiFiBerry DSP (falls unterstützt):**
```bash
# Bass-Kanal
dsptoolkit tone-control ls 200Hz 3db --channel 0

# Mitten/Höhen-Kanal
dsptoolkit tone-control hs 5000Hz 2db --channel 1
```

---

## 📝 MESSUNG CHECKLISTE

### **Vor der Messung:**
- [ ] REW installiert und konfiguriert
- [ ] Messmikrofon kalibriert
- [ ] Audio-Setup getestet
- [ ] Bose Wave in normaler Position
- [ ] Raum vorbereitet (ruhig, normal)

### **Während der Messung:**
- [ ] Referenz-Lautstärke eingestellt (50%)
- [ ] Mikrofon-Position: 1m, auf Höhe
- [ ] 3-5 Messungen durchführen
- [ ] Jede Messung speichern
- [ ] Durchschnitt bilden

### **Nach der Messung:**
- [ ] Frequenzgang analysieren
- [ ] EQ-Einstellungen ableiten
- [ ] DSP-Parameter berechnen
- [ ] HiFiBerry DSP konfigurieren
- [ ] Vergleichs-Messung durchführen
- [ ] Anpassungen vornehmen

---

## 🎯 ERWARTETE ERGEBNISSE

### **Typischer Bose Wave Frequenzgang:**

**Basierend auf Recherche:**
- **20-100 Hz:** +2-4 dB (Bass durch Waveguide)
- **100-300 Hz:** +1-3 dB (Bass warm)
- **300-1000 Hz:** 0 dB (Mitten flach)
- **1000-5000 Hz:** +1-2 dB (Präsenz)
- **5000-20000 Hz:** +2-3 dB (Höhen klar)

**ABER:** Exakte Werte durch Messung bestimmen!

---

## 📚 RESSOURCEN

### **REW Dokumentation:**
- [REW User Guide](https://www.roomeqwizard.com/help/helpcontents.html)
- [REW Measurement Guide](https://www.roomeqwizard.com/help/helpmeasurements.html)
- [REW EQ Guide](https://www.roomeqwizard.com/help/helpeq.html)

### **Messmikrofone:**
- **UMIK-1:** [MiniDSP UMIK-1](https://www.minidsp.com/products/acoustic-measurement/umik-1)
- **Behringer ECM8000:** Günstige Alternative
- **Dayton Audio EMM-6:** Gute Preis-Leistung

### **Kalibrierung:**
- UMIK-1: Kalibrierungsdatei vom Hersteller
- Andere: Hersteller-Kalibrierungsdatei oder externe Kalibrierung

---

## ⚠️ WICHTIGE HINWEISE

### **1. Kalibrierung ist KRITISCH:**
- ❌ Ohne Kalibrierung sind Messungen ungenau!
- ✅ Verwende immer kalibriertes Mikrofon!

### **2. Raum-Akustik:**
- Messung im normalen Hörraum
- Mehrere Positionen für Durchschnitt
- Raum-Moden berücksichtigen

### **3. Lautstärke:**
- Gleiche Lautstärke für alle Messungen
- Nicht zu laut (Hörschäden vermeiden)
- -12 dB Sicherheitsmarge in REW

### **4. Wiederholbarkeit:**
- Mehrere Messungen durchführen
- Durchschnitt bilden
- Abweichungen dokumentieren

---

## 🔄 ITERATIVER PROZESS

### **Schritt 1: Referenz-Messung**
- Bose Wave Original messen
- Frequenzgang dokumentieren

### **Schritt 2: DSP-Einstellung**
- EQ-Parameter aus REW ableiten
- HiFiBerry DSP konfigurieren

### **Schritt 3: Vergleichs-Messung**
- HiFiBerry mit DSP messen
- Mit Original vergleichen

### **Schritt 4: Anpassung**
- Unterschiede identifizieren
- DSP anpassen
- Wiederholen bis zufriedenstellend

---

## 🔄 HIFIBERRYOS EIGENE MESS-TOOLS

### **HiFiBerryOS hat eingebaute Mess-Tools:**

**Gefunden im Projekt:**
- `/opt/hifiberry/bin/run-measurement` - Automatische Messung
- `/opt/hifiberry/bin/room-measure` - Raum-Messung
- `/opt/hifiberry/bin/record-sweep` - Sweep aufzeichnen
- `/opt/hifiberry/bin/roomeq-preset` - Room EQ Presets

**Unterstützte Mikrofone:**
- ✅ HiFiBerry Mic
- ✅ MiniDSP UMIK-1 (18dB amplification)
- ✅ Dayton UMM-6

**Vorteil:**
- Direkt auf HiFiBerryOS verfügbar
- Automatische Verarbeitung
- Kann für Vergleichs-Messung verwendet werden

**Nachteil:**
- Nur für HiFiBerryOS (nicht für Bose Wave Original)
- Benötigt HiFiBerryOS auf Pi

---

## 📊 REW → HIFIBERRY DSP KONVERTIERUNG

### **1. REW Export-Formate:**

**REW kann exportieren:**
- Parametric EQ (Text)
- IIR Filter (Text)
- FIR Filter (WAV)
- Filter Settings (verschiedene Formate)

**Für HiFiBerry DSP:**
- Parametric EQ → `dsptoolkit apply-iir-filters`
- Tone Control → `dsptoolkit tone-control`

---

### **2. Konvertierungs-Schritte:**

**Schritt 1: REW EQ berechnen**
1. REW → "EQ" Tab
2. Target Curve wählen
3. "Match Response to Target" klicken
4. EQ-Parameter anzeigen

**Schritt 2: Export**
1. REW → "Export" → "Filter Settings"
2. Format: "Text" oder "Parametric EQ"
3. Speichern als: `bose_wave_eq.txt`

**Schritt 3: Konvertierung**
```bash
# Beispiel: REW Export
# Filter 1: PEQ, 80 Hz, Q=1.0, +3 dB
# Filter 2: PEQ, 200 Hz, Q=0.7, +2 dB
# Filter 3: PEQ, 5000 Hz, Q=1.0, +2 dB

# HiFiBerry DSP (falls unterstützt):
dsptoolkit apply-iir-filters peq 80Hz 1.0 3db
dsptoolkit apply-iir-filters peq 200Hz 0.7 2db
dsptoolkit apply-iir-filters peq 5000Hz 1.0 2db
```

**Schritt 4: Vereinfachung (falls Parametric EQ nicht unterstützt)**
```bash
# Tone Control Approximation:
# Bass: Durchschnitt der Bass-Filter
# Treble: Durchschnitt der Treble-Filter

dsptoolkit tone-control ls 200Hz 2.5db  # Bass
dsptoolkit tone-control hs 5000Hz 2db    # Treble
```

---

## 🎯 PRAKTISCHE SCHRITT-FÜR-SCHRITT-ANLEITUNG

### **Phase 1: Vorbereitung (30 Min)**

1. **REW installieren:**
   - [REW Download](https://www.roomeqwizard.com/)
   - Java installieren (falls nötig)
   - REW starten und testen

2. **Messmikrofon besorgen/kalibrieren:**
   - **Empfohlen:** UMIK-1 (USB, kalibriert)
   - **Alternative:** Behringer ECM8000 + Audio-Interface
   - Kalibrierungsdatei laden in REW

3. **Audio-Setup:**
   - Bose Wave → Computer (Line-In oder USB)
   - Messmikrofon → Computer (USB oder Audio-Interface)
   - Test: Sweep abspielen und aufzeichnen

---

### **Phase 2: Referenz-Messung (15 Min)**

1. **Raum vorbereiten:**
   - Bose Wave in normaler Position
   - Raum ruhig (keine Störgeräusche)
   - Mikrofon: 1m Abstand, auf Höhe

2. **REW konfigurieren:**
   - Input: Messmikrofon
   - Output: Computer Audio (für Sweep)
   - Sample Rate: 48 kHz
   - Sweep Length: 256k

3. **Messung durchführen:**
   - Bose Wave auf 50% Lautstärke
   - REW → "Measure" → "Start Measurement"
   - 3-5 Messungen wiederholen
   - Speichern als: `Bose_Wave_Original.spl`

4. **Durchschnitt bilden:**
   - REW → "All SPL" → "Average"
   - Speichern als: `Bose_Wave_Original_Avg.spl`

---

### **Phase 3: Analyse (20 Min)**

1. **Frequenzgang analysieren:**
   - REW → "All SPL" → Kurve anzeigen
   - Bereiche identifizieren:
     - Bass (20-300 Hz)
     - Mitten (300-3000 Hz)
     - Höhen (3000-20000 Hz)

2. **EQ berechnen:**
   - REW → "EQ" Tab
   - Target Curve: "Flat" oder "Harman"
   - "Match Response to Target" klicken
   - EQ-Parameter anzeigen

3. **Dokumentieren:**
   - Screenshot der Frequenzgang-Kurve
   - EQ-Parameter notieren
   - Besonderheiten dokumentieren

---

### **Phase 4: DSP-Einstellung (30 Min)**

1. **EQ-Parameter konvertieren:**
   - REW Export → HiFiBerry DSP Format
   - Parametric EQ oder Tone Control

2. **HiFiBerry DSP konfigurieren:**
   ```bash
   # Auf HiFiBerryOS:
   dsptoolkit tone-control ls 200Hz 2.5db
   dsptoolkit tone-control hs 5000Hz 2db
   dsptoolkit store-settings
   ```

3. **Service erstellen:**
   - `/etc/systemd/system/bose-wave3-dsp.service`
   - Automatische Anwendung beim Boot

---

### **Phase 5: Vergleichs-Messung (15 Min)**

1. **HiFiBerry mit DSP messen:**
   - Gleiche Position, gleiche Lautstärke
   - REW → "Measure" → "Start Measurement"
   - Speichern als: `HiFiBerry_DSP.spl`

2. **Vergleich:**
   - REW → "All SPL" → Beide Kurven überlagern
   - Unterschiede identifizieren
   - Anpassungen vornehmen

3. **Iteration:**
   - DSP anpassen
   - Erneut messen
   - Wiederholen bis zufriedenstellend

---

## 📋 CHECKLISTE KOMPLETT

### **Hardware:**
- [ ] REW installiert
- [ ] Java installiert
- [ ] Messmikrofon vorhanden
- [ ] Kalibrierungsdatei geladen
- [ ] Audio-Setup getestet
- [ ] Bose Wave Original bereit

### **Messung:**
- [ ] Raum vorbereitet
- [ ] Mikrofon positioniert (1m, auf Höhe)
- [ ] Bose Wave auf 50% Lautstärke
- [ ] 3-5 Messungen durchgeführt
- [ ] Durchschnitt gebildet
- [ ] Ergebnisse gespeichert

### **Analyse:**
- [ ] Frequenzgang analysiert
- [ ] EQ-Parameter berechnet
- [ ] Dokumentation erstellt
- [ ] Screenshots gemacht

### **Umsetzung:**
- [ ] EQ-Parameter konvertiert
- [ ] HiFiBerry DSP konfiguriert
- [ ] Service erstellt
- [ ] Vergleichs-Messung durchgeführt
- [ ] Anpassungen vorgenommen
- [ ] Finale Dokumentation

---

## 🎓 TIPPS & TRICKS

### **1. Mehrere Positionen messen:**
- Nicht nur 1m, sondern auch 2m, 3m
- Durchschnitt bilden
- Raum-Moden berücksichtigen

### **2. Verschiedene Target Curves:**
- "Flat" - Neutral
- "Harman" - Ausgewogen
- "Custom" - Eigene Präferenz

### **3. Iterative Anpassung:**
- Nicht alles auf einmal ändern
- Schrittweise anpassen
- Jede Änderung testen

### **4. Dokumentation:**
- Jede Messung dokumentieren
- Parameter notieren
- Screenshots machen
- Vergleichs-Kurven speichern

---

## 📚 ZUSÄTZLICHE RESSOURCEN

### **REW Dokumentation:**
- [REW User Guide](https://www.roomeqwizard.com/help/helpcontents.html)
- [REW Measurement Guide](https://www.roomeqwizard.com/help/helpmeasurements.html)
- [REW EQ Guide](https://www.roomeqwizard.com/help/helpeq.html)

### **Messmikrofone:**
- **UMIK-1:** [MiniDSP UMIK-1](https://www.minidsp.com/products/acoustic-measurement/umik-1) - €75
- **Behringer ECM8000:** Günstige Alternative - €30
- **Dayton Audio EMM-6:** Gute Preis-Leistung - €50

### **HiFiBerryOS Mess-Tools:**
- `/opt/hifiberry/bin/run-measurement`
- `/opt/hifiberry/bin/room-measure`
- `/opt/hifiberry/doc/roomeq.md`

---

**Status:** ✅ Plan vollständig  
**Nächster Schritt:** REW installieren, Messmikrofon besorgen, Messung durchführen

