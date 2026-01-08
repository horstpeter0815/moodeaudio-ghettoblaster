# ignore_lcd Parameter - Erklärung

**Datum:** 2025-11-25 22:35

---

## Was ist `ignore_lcd`?

**Raspberry Pi Boot-Parameter** der die automatische LCD/DSI-Erkennung steuert.

### Werte:

- **`ignore_lcd=0`** (oder nicht gesetzt):
  - System versucht automatisch LCDs/DSI-Displays zu erkennen
  - Verwendet automatische Device Tree Overlays
  - Standard-Verhalten

- **`ignore_lcd=1`**:
  - System ignoriert automatische LCD-Erkennung
  - Manuelle Overlays müssen verwendet werden
  - Verhindert Konflikte zwischen Auto-Detection und manuellen Overlays

---

## Warum setzt Waveshare Script `ignore_lcd=1`?

**Grund:**
- Waveshare verwendet **Custom Overlays** (`WS_xinchDSI_Screen`)
- Auto-Detection könnte mit Custom Overlays kollidieren
- `ignore_lcd=1` erzwingt Verwendung der manuellen Overlays

---

## Test-Ergebnisse

### Mit `ignore_lcd=1` + echtem KMS:
- ❌ DSI-1 wird NICHT erkannt
- ❌ Nur `card0` (V3D)

### Mit `ignore_lcd=0` + echtem KMS:
- ❌ DSI-1 wird NICHT erkannt
- ❌ Nur `card0` (V3D)

### Mit fkms (ohne ignore_lcd):
- ✅ DSI-1 wird erkannt (`connected`, `1280x400`)
- ⚠️ CRTC-Problem bleibt

---

## Erkenntnis

**`ignore_lcd` ist NICHT das Problem!**

**Das Problem ist:**
- **Echtes KMS** (`vc4-kms-v3d`) erkennt DSI-1 nicht
- **fkms** erkennt DSI-1, aber hat CRTC-Problem

**Lösung:**
- Zurück zu fkms
- CRTC-Problem anders lösen

---

**Status:** `ignore_lcd` getestet, ist nicht das Problem

