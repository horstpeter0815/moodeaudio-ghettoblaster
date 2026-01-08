# CRTC-Problem Analyse - Finale Diagnose

**Datum:** 2025-11-25 23:05 CET  
**Status:** CRITICAL - FKMS erstellt keine CRTCs für DSI

## Problem-Zusammenfassung

### Symptome:
- DSI-1 wird erkannt: `connected` mit `1280x400` Mode
- DSI-1 bleibt `disabled` - kein CRTC zugewiesen
- Kernel-Log: `Bogus possible_crtcs: [ENCODER:32:DSI-32] possible_crtcs=0x0 (full crtc mask=0x0)`
- Kernel-Log: `[drm] Cannot find any crtc or sizes`

### Root Cause:
**FKMS (`vc4-fkms-v3d`) erstellt keine CRTCs für DSI-Connector.**

Dies ist ein bekanntes Limitation von FKMS:
- FKMS ist ein "Fake" KMS, der über Firmware läuft
- FKMS unterstützt DSI nicht vollständig - keine CRTC-Zuweisung
- Echtes KMS (`vc4-kms-v3d`) erkennt DSI-1 gar nicht

## Getestete Lösungen (alle fehlgeschlagen):

1. ✅ HDMI deaktiviert - hilft nicht (DSI bleibt disabled)
2. ✅ `video=DSI-1:1280x400@60` Parameter - hilft nicht
3. ✅ `fbcon=map=1` Parameter - hilft nicht
4. ✅ `force_hotplug=1` - hilft nicht
5. ✅ I2C-Konfiguration (I2C0/I2C1) - hilft nicht (ist nicht das Problem)
6. ✅ DIP-Switch-Änderung - hilft nicht (ist nicht das Problem)
7. ❌ Echtes KMS - DSI-1 wird nicht erkannt
8. ❌ Manuelle CRTC-Zuweisung - nicht möglich (keine CRTCs vorhanden)

## Warum DIP-Switches nicht helfen:

Das CRTC-Problem ist **unabhängig von I2C**:
- I2C wird nur für Panel-Initialisierung verwendet (Backlight, etc.)
- CRTC ist die Hardware-Komponente, die Pixel-Daten an DSI sendet
- FKMS erstellt keine CRTCs für DSI, egal welche I2C-Konfiguration

## Mögliche Lösungen (noch zu testen):

### Option 1: Custom Overlay mit expliziter CRTC-Definition
- Device Tree Overlay anpassen
- CRTC manuell definieren
- **Risiko:** Sehr komplex, könnte System instabil machen

### Option 2: Kernel-Patch für FKMS
- FKMS-Source patchen
- CRTC-Support für DSI hinzufügen
- **Risiko:** Sehr komplex, Kernel-Updates brechen Patch

### Option 3: Alternative Display-Stack
- Direkter Framebuffer-Zugriff (ohne DRM/KMS)
- Custom Display-Driver
- **Risiko:** Sehr komplex, viele Features fehlen

### Option 4: Warten auf Kernel-Update
- Raspberry Pi Foundation könnte FKMS verbessern
- **Risiko:** Ungewiss, könnte Jahre dauern

## Empfehlung:

**DIP-Switches umschalten wird das Problem NICHT lösen.**

Das Problem ist ein fundamentales FKMS-Limitation. Wir sollten:
1. **NICHT** die DIP-Switches ändern (hilft nicht)
2. **WEITER** nach alternativen Lösungen suchen
3. **PRÜFEN** ob es Kernel-Patches oder Workarounds gibt
4. **ERWÄGEN** ob ein komplett anderer Ansatz nötig ist

## Nächste Schritte:

1. Prüfe ob es bekannte Kernel-Patches für FKMS+DSI gibt
2. Prüfe ob wir das Overlay anpassen können
3. Prüfe ob es alternative Display-Treiber gibt
4. Erwäge ob wir auf ein anderes Display wechseln müssen

