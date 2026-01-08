# Gemeinsame Probleme: Pi 4 und Pi 5

## Überraschende Erkenntnis:

**Beide (Pi 4 und Pi 5) haben die GLEICHEN Probleme!**

## Gemeinsame Probleme:

### 1. CRTC-Problem
- ❌ **Pi 4:** "Cannot find any crtc or sizes"
- ❌ **Pi 5:** "Cannot find any crtc or sizes"
- **Ursache:** FKMS/True KMS erstellt keinen CRTC für DSI, obwohl Panel erkannt wird

### 2. ws_touchscreen bindet an 0x45
- ❌ **Pi 4:** ws_touchscreen bindet an Panel-Adresse (0x45) statt Touchscreen (0x14)
- ❌ **Pi 5:** ws_touchscreen bindet an Panel-Adresse (0x45) statt Touchscreen (0x14)
- **Ursache:** Driver-Name-Konflikt im panel-waveshare-dsi Driver

### 3. I2C Kommunikation
- ❌ **Pi 4:** I2C write failed: -121 (EIO)
- ❌ **Pi 5:** I2C write failed: -121 (EIO)
- **Ursache:** ws_touchscreen versucht mit Panel zu kommunizieren

### 4. Display erkannt aber schwarz
- ❌ **Pi 4:** DSI-1 connected, enabled, aber kein Bild
- ❌ **Pi 5:** DSI-1 connected, enabled, aber kein Bild
- **Ursache:** CRTC-Problem verhindert Bildausgabe

## Warum sind die Probleme gleich?

### Gemeinsame Architektur:
1. **Beide verwenden VC4 DRM Driver** (vc4-kms-v3d)
2. **Beide verwenden gleichen Waveshare Panel Driver** (panel-waveshare-dsi)
3. **Beide verwenden gleiches Device Tree Overlay** (vc4-kms-dsi-waveshare-panel)
4. **Beide haben gleiche KMS-Architektur** (FKMS oder True KMS)

### Unterschiede (die NICHT das Problem sind):
- **Pi 4:** 2-lane DSI, VideoCore I2C
- **Pi 5:** 4-lane DSI, RP1 I2C
- **Aber:** Das CRTC-Problem ist unabhängig von diesen Unterschieden!

## Root Cause:

Das Problem liegt **NICHT** in der Hardware-Unterschieden, sondern in:

1. **Waveshare Panel Driver Design:**
   - Driver erstellt DSI Connector
   - Aber FKMS/True KMS erstellt keinen CRTC dafür
   - → Display erkannt, aber kein CRTC = kein Bild

2. **Device Tree Overlay:**
   - Overlay bindet ws_touchscreen an Panel-Adresse
   - → I2C-Konflikte

3. **KMS-Architektur:**
   - FKMS fragt Firmware nach Displays
   - Firmware kennt DSI nicht
   - → Kein CRTC erstellt

## Lösung muss für beide funktionieren:

1. **FKMS Patch** (wie wir vorher entwickelt haben)
   - Erstellt CRTC für DSI auch wenn Firmware es nicht meldet
   - Funktioniert für Pi 4 und Pi 5

2. **disable_touch Parameter**
   - Verhindert ws_touchscreen-Laden
   - Funktioniert für Pi 4 und Pi 5

3. **Panel Driver Patch**
   - Korrigiert Driver-Name
   - Funktioniert für Pi 4 und Pi 5

---

**Fazit:** Das Problem ist **software-seitig** (Driver/Overlay/KMS), nicht hardware-seitig. Deshalb sind Pi 4 und Pi 5 betroffen.

