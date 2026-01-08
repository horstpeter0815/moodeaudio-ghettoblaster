# SYSTEME ÜBERSICHT

**Datum:** 03.12.2025  
**Status:** 3 Systeme im Projekt

---

## SYSTEM 1: HIFIBERRYOS PI 4

**IP:** 192.168.178.199  
**System:** HiFiBerryOS (Buildroot)  
**Hardware:** Raspberry Pi 4  
**Audio:** HiFiBerry DAC+ Pro  
**Display:** HDMI (1280x400)  
**Status:** ✅ Läuft

**Erkenntnisse:**
- Display Rotation gelöst
- Volume auf 0% (Auto-Mute)
- Web-Visualizer implementiert
- Config-Management optimiert

---

## SYSTEM 2: MOODE PI 5 (GHETTOPI4)

**IP:** 192.168.178.134  
**System:** moOde Audio (Debian)  
**Hardware:** Raspberry Pi 5 Model B Rev 1.1 (8GB) ⚠️ **PI 5 - NOT PI 4!**  
**Kernel:** 6.12.47+rpt-rpi-2712 (Pi 5 specific)  
**Audio:** HDMI (kein HiFiBerry)  
**Display:** HDMI 1280x400 (rotated)  
**Status:** ⏳ Display issues - Chromium not starting

**Implementiert:**
- MPD Service optimiert
- Volume auf 0% (Auto-Mute)
- Config-Validierung
- Service-Abhängigkeiten optimiert

---

## SYSTEM 3: MOODE PI 4 (NEU)

**SD-Karte:** /dev/disk4  
**System:** moOde Audio (frisch gebrannt)  
**Hardware:** Raspberry Pi 4  
**Status:** ⏳ Wird konfiguriert

**Nächste Schritte:**
- SD-Karte konfigurieren
- Display Rotation setzen
- HiFiBerry Overlay (falls vorhanden)
- System testen

---

## PARALLELARBEIT

**Vorteile:**
- Vergleich zwischen Systemen
- Erkenntnisse übertragen
- Schnellere Problemlösung
- Besseres Verständnis

---

**Status:** ✅ 3 Systeme, ⏳ Konfiguration läuft

