# Hard Reset Test Plan

**Datum:** 2025-11-25 22:20  
**Status:** Hard Reset durchgeführt, warte auf Boot

---

## Was passiert ist

**Vergleichsergebnisse:**
- ✅ Beide Displays zeigen **GLEICHE** CRTC-Fehler
- ✅ Beide Displays zeigen **GLEICHE** DSI-1 Erkennung
- ⚠️ **UNTERSCHIEDLICHE** I2C-Fehler (-110 vs -5)

**Erkenntnis:**
- Problem ist **NICHT** hardware-spezifisch
- **CRTC-Problem** betrifft beide Displays
- **Konfigurations-Problem**, nicht Hardware-Defekt

---

## Nach Hard Reset

### Tests durchführen:

1. **DSI-Erkennung**
2. **CRTC-Status**
3. **Framebuffer**
4. **I2C-Status**
5. **LED-Status** (wichtig!)
6. **Display-Status** (wichtig!)

### Vergleich mit vorherigen Ergebnissen:

- **Gleiche Fehler?** → Konfigurations-Problem bestätigt
- **Andere Fehler?** → Hardware-Reset hat geholfen
- **Keine Fehler?** → Problem gelöst!

---

## Nächste Schritte

**Wenn Hard Reset nichts ändert:**
→ **CRTC-Problem** systematisch lösen

**Wenn Hard Reset hilft:**
→ Problem war Timing/Initialisierung

**Warte auf Boot und führe Tests durch...**

