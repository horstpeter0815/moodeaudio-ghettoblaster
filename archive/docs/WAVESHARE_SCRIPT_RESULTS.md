# Waveshare Script Test - Ergebnisse

**Datum:** 2025-11-25 22:30  
**Kernel:** 6.12.47+rpt-rpi-v8  
**Script Version:** 6.6.51

---

## Ergebnis

**❌ Script funktioniert NICHT für Kernel 6.12.47**

### Probleme:

1. **Kernel-Version Mismatch:**
   - Script unterstützt max. Kernel 6.6.51
   - Unser Kernel: 6.12.47
   - Module: "disagrees about version of symbol module_layout"

2. **Echtes KMS Problem:**
   - Script verwendet `vc4-kms-v3d` (echtes KMS)
   - Bei uns: DSI-1 wird nicht erkannt (nur card0)
   - Gleiches Problem wie vorher

3. **Overlay-Konflikte:**
   - `WS_xinchDSI_Screen` Overlay geladen
   - Aber Module können nicht geladen werden
   - Dependency Cycles (normal, aber Overlay funktioniert nicht)

---

## Was das Script gemacht hat:

**Config-Änderungen:**
- `dtoverlay=vc4-kms-v3d` (echtes KMS)
- `dtoverlay=WS_xinchDSI_Screen,SCREEN_type=5,I2C_bus=1`
- `dtoverlay=WS_xinchDSI_Touch,I2C_bus=1,invertedx,swappedxy`
- `ignore_lcd=1`
- `dtparam=i2c_vc=on`

**Aber:** Module für falschen Kernel → funktioniert nicht

---

## Erkenntnis

**Waveshare Script ist für ältere Kernel-Versionen.**

**Für Kernel 6.12.47:**
- Script funktioniert nicht
- Module inkompatibel
- Echtes KMS Problem bleibt

**Lösung:**
- Zurück zu fkms (wo DSI-1 erkannt wurde)
- CRTC-Problem anders lösen
- Oder: Kernel downgraden (nicht empfohlen)

---

**Status:** Script getestet, funktioniert nicht für unseren Kernel

