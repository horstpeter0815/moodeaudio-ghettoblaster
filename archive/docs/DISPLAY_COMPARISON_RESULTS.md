# Display Comparison Results

**Datum:** 2025-11-25 22:15  
**Vergleich:** 7.9" Display vs. Anderes Waveshare Display

---

## 7.9" Display Ergebnisse

**DSI-1:**
- ✅ `connected`
- ✅ `1280x400`

**CRTC:**
- ⚠️ `Bogus possible_crtcs: possible_crtcs=0x0 (full crtc mask=0x1)`
- ⚠️ 2 CRTC-Fehler

**Framebuffer:**
- ✅ `/dev/fb0` existiert

**I2C:**
- ❌ Fehler: `-110` (ETIMEDOUT)
- ❌ Viele Timeouts

**Panel-Device:**
- ✅ `1-0045` erkannt

---

## Anderes Display Ergebnisse

**DSI-1:**
- ✅ `connected`
- ✅ `1280x400` (GLEICH!)

**CRTC:**
- (Wird geprüft...)

**Framebuffer:**
- (Wird geprüft...)

**I2C:**
- ❌ Fehler: `-5` (EIO) - **ANDERS!**
- ⚠️ Weniger Fehler als 7.9"

**Panel-Device:**
- ✅ `1-0045` erkannt (GLEICH!)

---

## Vergleich

### GLEICH:
- ✅ DSI-1 erkannt (`connected`, `1280x400`)
- ✅ Panel-Device (`1-0045`)
- ✅ vc4 initialisiert

### UNTERSCHIEDLICH:
- ⚠️ **I2C-Fehler-Typ:**
  - 7.9": `-110` (ETIMEDOUT) - Bus antwortet nicht
  - Anderes: `-5` (EIO) - Bus aktiv, Panel antwortet falsch

**Interpretation:**
- **7.9" Display:** I2C-Bus antwortet nicht (Timeout)
- **Anderes Display:** I2C-Bus aktiv, aber Panel antwortet falsch (I/O Error)

**Das deutet auf Hardware-Unterschied hin!**

---

## Nächste Schritte

1. **CRTC-Status prüfen** (anderes Display)
2. **Framebuffer-Status prüfen** (anderes Display)
3. **LED-Status vergleichen** (beide Displays)
4. **Display-Status vergleichen** (beide Displays)

**Frage:** Zeigt das andere Display etwas? Oder blinkt LED auch?

---

**Status:** Tests laufen...

