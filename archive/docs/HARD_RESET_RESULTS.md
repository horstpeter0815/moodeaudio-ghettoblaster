# Hard Reset Test Results

**Datum:** 2025-11-25 22:40  
**Display:** 7.9" Waveshare, DIP-Switches I2C1  
**Config:** `vc4-fkms-v3d` + `vc4-kms-dsi-waveshare-panel,7_9_inch,i2c1`

---

## Ergebnisse nach Hard Reset

### ✅ Funktioniert:
- **DSI-1:** `connected`
- **Framebuffer:** `/dev/fb0` existiert
- **Panel-Device:** `1-0045` erkannt (I2C Bus 1)
- **Config:** `i2c1` korrekt

### ❌ Problem bleibt:
- **CRTC:** `possible_crtcs=0x0` (full crtc mask=0x1)
  - CRTC existiert, wird aber nicht zugewiesen
  - **Das ist das Hauptproblem!**

### ⚠️ I2C:
- (Wird geprüft...)

---

## Vergleich: Vor vs. Nach Hard Reset

**Vor Hard Reset:**
- I2C-Fehler: `-110` (ETIMEDOUT)
- Viele I2C-Timeouts

**Nach Hard Reset:**
- (Wird geprüft...)

---

## Hauptproblem identifiziert

**CRTC-Problem:**
- `possible_crtcs=0x0` bedeutet: DSI-Encoder hat keinen zugewiesenen CRTC
- `full crtc mask=0x1` bedeutet: Es gibt einen CRTC (mask bit 0 = CRTC 0)
- **Aber:** CRTC wird nicht dem DSI-Encoder zugewiesen!

**Das ist ein fkms-Problem!** fkms erstellt CRTCs, aber weist sie nicht richtig zu.

---

## Nächste Schritte

1. **I2C-Status prüfen** (nach Hard Reset)
2. **CRTC-Problem lösen:**
   - Option A: fkms patchen/konfigurieren
   - Option B: Echtes KMS verwenden (aber DSI-1 wird nicht erkannt)
   - Option C: CRTC manuell zuweisen

---

**Status:** Tests laufen...

