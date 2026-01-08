# NEUER AMP100 - OHNE KABEL TEST

**Datum:** 02.12.2025  
**Aktion:** Neuer AMP100 ohne DSP-Kabel testen

---

## VORGEHEN

### **Änderungen:**
- ✅ Stärkeres Netzteil angeschlossen (nicht mehr Power-Supply Problem)
- ✅ Neuer AMP100 angeschlossen
- ⏳ **OHNE DSP-Kabel testen** (um zu prüfen ob DSP/Kabel das Problem verursacht)

### **Test-Strategie:**
1. **OHNE KABEL:** Touchscreen isoliert testen
   - Kein AMP100 auf I2C Bus
   - Kein DSP-Kabel-Konflikt
   - Reiner Touchscreen-Test

2. **DANN MIT KABEL:** Falls ohne Kabel funktioniert
   - AMP100 wieder anschließen
   - DSP-Kabel wieder anschließen
   - Konflikt-Analyse

---

## TEST-ERGEBNISSE

### **Ohne AMP100 Kabel:**
- ⏳ I2C Bus 1 Status prüfen
- ⏳ Touchscreen Device erstellen
- ⏳ Driver-Bindung prüfen
- ⏳ I2C Read/Write Test
- ⏳ Touchscreen in xinput prüfen

---

## ERWARTETE ERGEBNISSE

### **Erfolg (ohne Kabel):**
- ✅ Touchscreen Device existiert
- ✅ Driver gebunden: `edt-ft5x06`
- ✅ Input Device erstellt
- ✅ Touchscreen in xinput erkannt
- ✅ I2C Read/Write funktioniert
- **→ Dann mit Kabel testen**

### **Falls weiterhin Problem (ohne Kabel):**
- ⚠️ Problem liegt nicht am DSP/Kabel
- ⚠️ Touchscreen selbst oder I2C Bus Problem
- ⚠️ Hardware-Defekt am Touchscreen

---

**Test in Arbeit...**

