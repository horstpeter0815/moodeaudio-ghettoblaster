# FINAL STATUS - 02.12.2025 09:15

## PI 2 (moOde Audio) - 192.168.178.134

### ✅ FUNKTIONIERT:
- **Display:** ✅ X Server läuft, localdisplay.service aktiv
- **MPD:** ✅ Service aktiv
- **PCM5122 Hardware:** ✅ Erkannt auf I2C Bus 13 (0x4d)
- **PCM5122 Kernel-Module:** ✅ Vorhanden (`snd_soc_pcm512x.ko.xz`)

### ❌ FUNKTIONIERT NICHT:
- **Audio:** ❌ Keine Soundkarte
  - **Problem:** Device Tree Overlay kann Bus 13 nicht targeten
  - **Versuchte Lösungen:**
    - Overlay mit `target-path` für Bus 13 → Fehlgeschlagen
    - Overlay mit `__fixups__` → Fehlgeschlagen  
    - Manuelles Driver-Binding → "Device or resource busy"
    - Systemd Service für manuelles Binding → Fehlgeschlagen
  - **Root Cause:** Overlay wird nicht geladen oder erstellt keine korrekten Device Tree Nodes

- **Touchscreen:** ❌ FT6236 Modul fehlt
  - `modprobe: FATAL: Module ft6236 not found`
  - Kernel: 6.12.47+rpt-rpi-2712
  - Modul nicht kompiliert

## PI 1 (RaspiOS) - 192.168.178.62

### ❌ FUNKTIONIERT NICHT:
- **Touchscreen:** ❌ FT6236 Modul fehlt (gleiches Problem)

## DURCHGEFÜHRTE ARBEITEN ÜBER NACHT:

1. **Audio Overlay:**
   - Mehrere Overlay-Varianten getestet
   - Bus 13 Targeting versucht
   - Manuelles Driver-Binding versucht
   - Systemd Services erstellt
   - **Ergebnis:** Keine funktionierende Lösung gefunden

2. **Touchscreen:**
   - FT6236 Modul-Problem identifiziert
   - **Ergebnis:** Benötigt Kernel-Modul-Kompilierung

## PROBLEME:

1. **I2C Bus 13:**
   - PCM5122 ist physisch auf Bus 13
   - Device Tree Overlays können Bus 13 nicht einfach targeten
   - Keine Standard-Symbol-Referenz für Bus 13 verfügbar

2. **FT6236:**
   - Kernel-Modul fehlt komplett
   - Benötigt Kernel-Update oder Modul-Kompilierung

## NÄCHSTE SCHRITTE (NICHT DURCHGEFÜHRT):

1. **Audio:**
   - Kernel-Device-Tree direkt modifizieren (nicht via Overlay)
   - Oder: Custom Kernel mit korrektem Bus 13 Overlay kompilieren
   - Oder: Hardware prüfen (HAT richtig aufgesteckt?)

2. **FT6236:**
   - Kernel-Modul kompilieren
   - Oder: Kernel-Update mit FT6236 Support

