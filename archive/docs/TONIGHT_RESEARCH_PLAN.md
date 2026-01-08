# Tonight's Research Plan - CRTC Problem

## Ziel
Das CRTC-Problem lösen: Warum erstellt fkms keinen CRTC für DSI, und wie können wir das beheben?

## Research Tasks

### Task 1: fkms DSI Support Research (60-90 Min)

**Fragen:**
1. Unterstützt fkms DSI überhaupt?
2. Gibt es bekannte fkms + DSI Probleme?
3. Wie funktioniert fkms CRTC-Erstellung?

**Quellen:**
- Raspberry Pi Kernel Source: `drivers/gpu/drm/vc4/vc4_firmware_kms.c`
- GitHub: `raspberrypi/linux` Issues mit "fkms" + "DSI"
- Raspberry Pi Forums: fkms DSI discussions
- Kernel Documentation: DRM/KMS

**Erwartetes Ergebnis:**
- Verstehen ob fkms DSI unterstützt
- Identifizieren ob es ein bekanntes Problem ist
- Finden von Workarounds oder Fixes

### Task 2: Waveshare Overlay Source Analysis (45-60 Min)

**Fragen:**
1. Wie ist das offizielle Waveshare Overlay strukturiert?
2. Gibt es CRTC-Definitionen im Overlay?
3. Welche KMS-Version wird empfohlen?

**Quellen:**
- GitHub: `waveshare/7.9inch-DSI-LCD`
- Device Tree Overlay Source Code
- Waveshare Wiki/Dokumentation
- Installation Guides

**Erwartetes Ergebnis:**
- Overlay-Struktur verstehen
- CRTC-Konfiguration identifizieren
- Empfohlene KMS-Version finden

### Task 3: vc4-kms-v3d-pi4 DSI Recognition (45-60 Min)

**Fragen:**
1. Warum wird DSI-1 nicht erkannt mit echtem KMS?
2. Braucht echtes KMS andere Overlay-Parameter?
3. Gibt es Konflikte zwischen Overlays?

**Quellen:**
- Kernel Source: `drivers/gpu/drm/vc4/vc4_dsi.c`
- Device Tree Bindings für vc4
- Raspberry Pi Dokumentation: KMS Configuration
- GitHub Issues: vc4 DSI problems

**Erwartetes Ergebnis:**
- Verstehen warum DSI-1 fehlt mit echtem KMS
- Finden der richtigen Overlay-Konfiguration
- Identifizieren von Overlay-Konflikten

### Task 4: Alternative Solutions Research (30-45 Min)

**Fragen:**
1. Gibt es alternative Display-Treiber?
2. Kann man Framebuffer ohne CRTC erstellen?
3. Gibt es Workarounds für fkms DSI?

**Quellen:**
- Linux DRM Documentation
- Framebuffer API
- Alternative Display Libraries (DirectFB, SDL)
- Raspberry Pi Community Solutions

**Erwartetes Ergebnis:**
- Alternative Ansätze identifizieren
- Workarounds finden
- Backup-Plan entwickeln

## Dokumentation

**Für jeden Task:**
1. Quellen sammeln
2. Key Findings dokumentieren
3. Code-Snippets speichern
4. Lösungsansätze notieren

## Output Files

1. `FKMS_DSI_RESEARCH.md` - fkms DSI Support Findings
2. `WAVESHARE_OVERLAY_ANALYSIS.md` - Overlay Structure Analysis
3. `VC4_KMS_DSI_RESEARCH.md` - Echter KMS DSI Research
4. `ALTERNATIVE_SOLUTIONS.md` - Alternative Ansätze

## Success Criteria

**Erfolg wenn:**
- ✅ Verstanden warum fkms keinen CRTC erstellt
- ✅ Identifiziert ob fkms DSI unterstützt
- ✅ Gefunden wie Waveshare Overlay konfiguriert werden sollte
- ✅ Mindestens 1 konkreter Lösungsansatz

## Time Estimate

**Total: 3-4 Stunden**

- Task 1: 60-90 Min
- Task 2: 45-60 Min
- Task 3: 45-60 Min
- Task 4: 30-45 Min

## Next Steps After Research

1. **Lösung implementieren** basierend auf Findings
2. **Testen** auf echtem Pi
3. **Iterieren** wenn nötig

