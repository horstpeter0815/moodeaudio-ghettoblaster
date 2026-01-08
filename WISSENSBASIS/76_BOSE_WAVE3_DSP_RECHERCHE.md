# BOSE WAVE 3 DSP - AUSGIEBIGE RECHERCHE

**Datum:** 03.12.2025  
**Zweck:** Ausgiebige Recherche über Bose Wave 3 DSP vor Implementierung  
**Status:** ✅ Recherche abgeschlossen

---

## 🔍 WICHTIGE ERKENNTNISSE

### **1. BOSE WAVE 3 HAT SEHR BEGRENZTE DSP-EINSTELLUNGEN:**

**Verfügbare Einstellungen:**
- ✅ **Bass:** Nur "NORMAL" oder "REDUZIERT" (keine dB-Werte!)
- ❌ **Treble/Höhen:** KEINE Einstellung verfügbar!
- ❌ **Equalizer:** KEINE detaillierten EQ-Einstellungen!

**Einstellungsmethode:**
1. "Alarm Setup (Menu)" Taste gedrückt halten
2. "Tune/MP3 >" Taste wiederholt drücken bis "BASS-" erscheint
3. "Time +" oder "Time -" für NORMAL/REDUZIERT
4. Gilt für alle Audioquellen

**Quellen:**
- [Bose Support Artikel HC2475](https://www.bose.ie/en_ie/support/articles/HC2475/productCodes/wms_3/article.html)
- [Bose Bedienungsanleitung PDF](https://trete.de/wordpress/wp-content/uploads/2022/05/Bose-Wave-Music-System-III.pdf)

---

### **2. KLANGQUALITÄT KOMMT VON HARDWARE, NICHT DSP:**

**Acoustic Waveguide Technology:**
- Patentierte akustische Röhren im Inneren
- Natürliche Verstärkung der Bassfrequenzen durch Hardware-Design
- **NICHT durch DSP erreicht!**

**Frequenzbereich:**
- **55 Hz bis über 21 kHz** (für Gerät dieser Größe bemerkenswert)
- Messungen zeigen flachen Frequenzgang in diesem Bereich

**Quellen:**
- [Spiegel Test](https://www.spiegel.de/netzwelt/gadgets/bose-wave-music-system-iii-im-test-a-833140.html)
- [Connect Living Test](https://www.connect-living.de/testbericht/bose-wave-music-system-iii-im-test-1311130.html)

---

### **3. KEINE ÖFFENTLICHEN DSP-EINSTELLUNGEN:**

**Bose veröffentlicht NICHT:**
- ❌ Spezifische DSP-Algorithmen
- ❌ Frequenzgang-Kurven
- ❌ Equalizer-Einstellungen
- ❌ House Curves

**Bose "House Curve":**
- Existiert, aber nicht öffentlich dokumentiert
- Proprietär und geschützt

---

### **4. MÖGLICHE ANSÄTZE FÜR NACHBILDUNG:**

#### **A. Harman House Curves als Referenz:**
- Gut dokumentierte Referenzkurven
- Können als Ausgangspunkt dienen
- Betonen bestimmte Frequenzbereiche für ausgewogenes Hörerlebnis

**Quelle:** [Arylic Forum Diskussion](https://forum.arylic.com/t/dsp-for-bose-wave/2530)

#### **B. Frequenzgang-Messung:**
- Messmikrofon + REW (Room EQ Wizard) verwenden
- Frequenzgang des Bose Wave Systems messen
- DSP entsprechend anpassen

**Quelle:** [Arylic Forum](https://forum.arylic.com/t/dsp-for-bose-wave/2530)

#### **C. Typische Bose-Klangcharakteristika (subjektiv):**
- **Warm, bassbetont** (durch Waveguide Hardware)
- **Klar, raumfüllend** (durch Waveguide Design)
- **Ausgewogen** (durch Hardware-Optimierung)

**ABER:** Diese kommen hauptsächlich von Hardware, nicht DSP!

---

## ⚠️ KRITISCHE ERKENNTNISSE

### **1. BOSE WAVE 3 HAT KEINEN PARAMETRISCHEN EQUALIZER:**
- Nur Bass: NORMAL/REDUZIERT
- Keine Treble-Einstellung
- Keine Frequenz-spezifischen Anpassungen

### **2. KLANG KOMMT VON HARDWARE:**
- Acoustic Waveguide Technology (patentiert)
- Physikalische Bass-Verstärkung durch Röhren-Design
- **Kann NICHT durch DSP nachgebildet werden!**

### **3. KEINE SPEZIFISCHEN DSP-WERTE VERFÜGBAR:**
- Bose veröffentlicht keine DSP-Parameter
- Keine Frequenzgang-Kurven
- Keine Equalizer-Einstellungen

---

## 💡 MÖGLICHE LÖSUNGSANSÄTZE

### **Ansatz 1: Harman House Curves**
- Verwende dokumentierte Referenzkurven
- Anpassung an persönliche Vorlieben
- **Problem:** Nicht spezifisch für Bose Wave 3

### **Ansatz 2: Subjektive Klangcharakteristika**
- Warm, bassbetont (Bass +2-3 dB)
- Klar, brillant (Treble +2-3 dB)
- **Problem:** Subjektiv, nicht gemessen

### **Ansatz 3: Frequenzgang-Messung**
- Bose Wave 3 mit REW messen
- DSP entsprechend anpassen
- **Problem:** Erfordert Hardware-Messung

### **Ansatz 4: Einfache Bass/Treble Anpassung**
- Bass leicht anheben (warm)
- Treble leicht anheben (klar)
- **Problem:** Nicht spezifisch für Bose Wave 3

---

## 📊 ZUSAMMENFASSUNG

### **Was wir WISSEN:**
- ✅ Bose Wave 3 hat nur Bass: NORMAL/REDUZIERT
- ✅ Keine Treble-Einstellung
- ✅ Frequenzbereich: 55 Hz - 21 kHz
- ✅ Klang kommt von Acoustic Waveguide Hardware

### **Was wir NICHT WISSEN:**
- ❌ Spezifische DSP-Einstellungen
- ❌ Frequenzgang-Kurven
- ❌ Equalizer-Parameter
- ❌ Bose House Curve Details

### **Was wir TUN KÖNNEN:**
- ✅ Subjektive Klangcharakteristika nachbilden
- ✅ Harman Curves als Referenz verwenden
- ✅ Bass/Treble anpassen (warm, klar)
- ⚠️ **ABER:** Exakte Nachbildung unmöglich ohne Hardware-Messung

---

## 🎯 EMPFEHLUNG

**Da Bose Wave 3 keine detaillierten DSP-Einstellungen hat:**
1. **Subjektive Klangcharakteristika verwenden:**
   - Bass: +2-3 dB (warm, voll)
   - Treble: +2-3 dB (klar, brillant)

2. **Oder Harman House Curves als Referenz:**
   - Gut dokumentiert
   - Ausgewogene Kurven

3. **Oder Frequenzgang messen:**
   - Mit REW und Messmikrofon
   - Dann DSP entsprechend anpassen

**WICHTIG:** Exakte Nachbildung ist ohne Hardware-Messung nicht möglich!

---

## 📚 QUELLEN

1. [Bose Support - Bass Einstellung](https://www.bose.ie/en_ie/support/articles/HC2475/productCodes/wms_3/article.html)
2. [Bose Bedienungsanleitung PDF](https://trete.de/wordpress/wp-content/uploads/2022/05/Bose-Wave-Music-System-III.pdf)
3. [Spiegel Test - Waveguide Technology](https://www.spiegel.de/netzwelt/gadgets/bose-wave-music-system-iii-im-test-a-833140.html)
4. [Connect Living Test - Frequenzbereich](https://www.connect-living.de/testbericht/bose-wave-music-system-iii-im-test-1311130.html)
5. [Arylic Forum - DSP für Bose Wave](https://forum.arylic.com/t/dsp-for-bose-wave/2530)

---

**Status:** ✅ Recherche abgeschlossen  
**Nächster Schritt:** Entscheidung über Implementierungs-Ansatz
