# Online Research Findings - Waveshare 7.9" DSI LCD Problem

## Problem
- Grüne LED blinkt, kein Bild
- Panel wird nicht initialisiert
- ws_touchscreen blockiert panel_waveshare_dsi
- Kein Mode wird gesetzt
- Framebuffer leer oder vertikal (400x1280 statt 1280x400)

## Gefundene Probleme und Lösungen

### 1. Power-Versorgung
- **Problem:** Unzureichende Power-Versorgung
- **Lösung:** Mindestens 5V/2A (Display benötigt ≥0.6A)
- **Prüfung:** `vcgencmd get_throttled` zeigt Power-Probleme

### 2. DSI-Kabel-Verbindung
- **Problem:** Kabel lose oder falsch orientiert
- **Lösung:** 
  - Gold-Kontakte richtig ausrichten
  - Kabel muss richtig eingesteckt sein (zweimal klicken)
  - Physische Prüfung erforderlich

### 3. System-Updates
- **Problem:** Updates können Display-Treiber überschreiben
- **Lösung:** Treiber nach Updates neu installieren
- **Hinweis:** Aktuelles System: Trixie (Debian 13) - möglicherweise zu neu

### 4. Kernel-Kompatibilität
- **Problem:** Kernel 6.12.47+rpt-rpi-v8 (Trixie) möglicherweise nicht kompatibel
- **Lösung:** 
  - Ältere OS-Version testen (Bullseye/Buster)
  - Waveshare Pre-installed Image verwenden

### 5. Driver/Overlay Konfiguration
- **Problem:** disable_touch funktioniert nicht
- **Lösung:** 
  - Pre-installed Image testen
  - Manuelle Driver-Installation

### 6. GitHub Issues
- Raspberry Pi Linux Repository: Issues zu Waveshare DSI Displays
- Waveshare GitHub Repository: Offizielle Treiber und Support

## Empfohlene Nächste Schritte

1. **Power-Versorgung prüfen:** `vcgencmd get_throttled`
2. **DSI-Kabel physisch prüfen:** Verbindung und Orientierung
3. **Waveshare Pre-installed Image testen:** Funktioniert das Display dort?
4. **Ältere OS-Version testen:** Bullseye statt Trixie
5. **System-Updates durchführen:** `sudo apt-get update && sudo apt-get full-upgrade`

## Aktuelle Konfiguration
- **config.txt:** `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch`
- **cmdline.txt:** `video=DSI-2:1280x400@60`
- **OS:** Trixie (Debian 13)
- **Kernel:** 6.12.47+rpt-rpi-v8

## Status
- Panel Driver: ws_touchscreen (sollte panel_waveshare_dsi sein)
- Framebuffer: 400,1280 (vertikal, sollte 1280,400 sein)
- DSI-1: connected, kein Mode
- Backlight: 255 (funktioniert)
- LED: Blinkt (nicht initialisiert)

## KRITISCHE ERKENNTNISSE AUS GITHUB ISSUES

### Waveshare GitHub Repository (waveshareteam/Waveshare-DSI-LCD)

**Issue #31:** "Latest RPI OS not installing natively this driver"
- **Lösung:** Ältere Raspberry Pi OS Version verwenden
- **Empfohlen:** 2023-12-05-raspios-bookworm-arm64.img.xz (Kernel 6.6.20)
- **Problem:** Neueste Raspberry Pi OS Versionen haben Probleme

**Issue #29:** "Driver for 6.6.20 hangs"
- Driver hängt beim Installieren
- Installation schlägt fehl

**Issue #27:** "Drivers still not working since 6.1.21"
- Probleme seit Kernel 6.1.21
- Benutzer fordert Source Code Release (GPLv2)

**Issue #24:** "Drivers not working"
- Letzter funktionierender Kernel: 6.1.21
- Probleme mit neueren Kernels

**Issue #21:** "Provide Drivers for 6.1.64-v8+"
- Modprobe Error: "Exec format error"
- Driver-Kompatibilitätsprobleme mit neueren Kernels

### Raspberry Pi Linux Repository (raspberrypi/linux)

**Issue #5550:** "Waveshare 7.9\" DSI not working android pi4"
- **Symptome:** Display bleibt aus, LED blinkt
- **Funktioniert:** Mit Android (LineageOS20)
- **Problem:** Mit Raspberry Pi OS funktioniert es nicht

**Issue #6035:** "DSI Panel on Pi 5 and 6.6 Kernel"
- **Device Tree Error:** "dterror: invalid target (phandle -908620279)"
- **Problem:** Device Tree Overlay Fehler mit Kernel 6.6

## HAUPTPROBLEM IDENTIFIZIERT

**KERNEL-KOMPATIBILITÄT:**
- **Aktueller Kernel:** 6.12.47+rpt-rpi-v8 (Trixie/Debian 13)
- **Problem:** Dieser Kernel ist möglicherweise **NICHT kompatibel** mit Waveshare DSI Displays
- **Empfohlene Kernel:** 6.1.21 oder älter
- **Empfohlenes OS:** Bullseye (Debian 11) oder Bookworm (Debian 12) mit älterem Kernel

## LÖSUNGSVORSCHLÄGE

1. **OS-Version Downgrade:**
   - Bullseye (Debian 11) mit Kernel 6.1.21 oder älter
   - Bookworm (Debian 12) mit Kernel 6.6.20 (2023-12-05 Image)

2. **Waveshare Pre-installed Image testen:**
   - Funktioniert das Display mit dem Pre-installed Image?
   - Wenn ja: Software-Problem bestätigt

3. **Kernel Downgrade (falls möglich):**
   - Älteren Kernel installieren, der mit Waveshare kompatibel ist

4. **Alternative:**
   - Warten auf Waveshare Driver-Update für Kernel 6.12.47
   - Oder Source Code anfordern (GPLv2) und selbst kompilieren

