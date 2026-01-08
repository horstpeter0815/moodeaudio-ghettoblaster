# Nightly Research Progress - CRTC Problem

**Start:** 2025-11-26 00:30 CET  
**Plan:** `TONIGHT_RESEARCH_PLAN.md`

---

## Task Status

### ✅ Task 1: fkms DSI Support Research (60-90 Min)
**Status:** IN PROGRESS

**Findings bisher:**
- ✅ Waveshare empfiehlt `vc4-kms-v3d` (echtes KMS), NICHT `vc4-fkms-v3d`
- ✅ fkms erstellt keine CRTCs für DSI (bekanntes Problem)
- ⏳ Prüfe fkms Source Code: `drivers/gpu/drm/vc4/vc4_firmware_kms.c`
- ⏳ GitHub Issues mit "fkms" + "DSI" suchen

**Nächste Schritte:**
- [ ] fkms Source Code analysieren
- [ ] GitHub Issues durchsuchen
- [ ] Raspberry Pi Forums prüfen

---

### ⏳ Task 2: Waveshare Overlay Source Analysis (45-60 Min)
**Status:** PENDING

**Findings bisher:**
- ✅ Overlay-Struktur analysiert (kein explizites CRTC)
- ✅ `i2c1` Parameter wechselt zu GPIO I2C
- ⏳ Offizielles Waveshare Repository prüfen
- ⏳ Installation Script analysieren

**Nächste Schritte:**
- [ ] Waveshare GitHub Repository durchsuchen
- [ ] Installation Script analysieren
- [ ] Offizielle Config-Beispiele prüfen

---

### ⏳ Task 3: vc4-kms-v3d-pi4 DSI Recognition (45-60 Min)
**Status:** PENDING

**Findings bisher:**
- ✅ Mit echtem KMS wird DSI-1 nicht erkannt
- ✅ Config aktuell: `vc4-kms-v3d` (nicht pi4-spezifisch)
- ⏳ Warum wird DSI-1 nicht erkannt?
- ⏳ Overlay-Konflikte prüfen

**Nächste Schritte:**
- [ ] Kernel Source analysieren: `drivers/gpu/drm/vc4/vc4_dsi.c`
- [ ] Device Tree Bindings prüfen
- [ ] Overlay-Reihenfolge testen

---

### ⏳ Task 4: Alternative Solutions Research (30-45 Min)
**Status:** PENDING

**Findings bisher:**
- ⏳ Alternative Display-Treiber suchen
- ⏳ Framebuffer ohne CRTC prüfen
- ⏳ Workarounds für fkms DSI

**Nächste Schritte:**
- [ ] Linux DRM Documentation lesen
- [ ] Framebuffer API prüfen
- [ ] Alternative Libraries (DirectFB, SDL) recherchieren

---

## Output Files (geplant)

1. ⏳ `FKMS_DSI_RESEARCH.md` - fkms DSI Support Findings
2. ⏳ `WAVESHARE_OVERLAY_ANALYSIS.md` - Overlay Structure Analysis
3. ⏳ `VC4_KMS_DSI_RESEARCH.md` - Echter KMS DSI Research
4. ⏳ `ALTERNATIVE_SOLUTIONS.md` - Alternative Ansätze

---

## Aktueller Fokus

**Task 1:** fkms DSI Support Research
- Analysiere fkms Source Code
- Suche nach bekannten Issues
- Verstehe CRTC-Erstellung

---

## Notes

- System rebootet mit `vc4-fkms-v3d` (Config geändert)
- Warte auf Boot, dann weiter mit Task 1

