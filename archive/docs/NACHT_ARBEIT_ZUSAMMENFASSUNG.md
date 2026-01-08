# NACHT-ARBEIT ZUSAMMENFASSUNG - 02.12.2025

## DURCHGEFÜHRTE ARBEITEN:

### 1. AUDIO OVERLAY PROBLEM
- **Problem:** PCM5122 auf I2C Bus 13, Overlay nutzt Bus 1
- **Versuche:**
  - Overlay auf Bus 13 angepasst (`target-path = "/soc@107c000000/107d508200.i2c"`)
  - Overlay mit `__fixups__` für Bus 13
  - Standard hifiberry-dacplus Overlay getestet (funktioniert auch nicht)
  - Manuelles Driver-Binding versucht (funktioniert nicht)
  - Systemd Service für manuelles Binding erstellt (fehlgeschlagen)

- **Status:** ❌ Audio funktioniert nicht
- **Grund:** Device Tree Overlay kann Bus 13 nicht korrekt targeten oder wird nicht geladen

### 2. TOUCHSCREEN FT6236 PROBLEM
- **Problem:** FT6236 Kernel-Modul fehlt
- **Status:** ❌ Modul nicht im Kernel (6.12.47+rpt-rpi-2712)
- **Grund:** Modul nicht kompiliert oder nicht verfügbar

### 3. DISPLAY
- **Status:** ✅ Funktioniert (X Server läuft, localdisplay.service aktiv)

### 4. MPD
- **Status:** ✅ Service aktiv (aber keine Soundkarte, daher kein Audio)

## ERKENNTNISSE:

1. **I2C Bus 13 Problem:**
   - PCM5122 ist physisch auf Bus 13 (0x4d sichtbar)
   - Device Tree Overlays können Bus 13 nicht einfach via `target-path` targeten
   - `target = <&i2c1>` funktioniert nur für Bus 1
   - Bus 13 hat kein Standard-Symbol für Overlays

2. **FT6236:**
   - Kernel-Modul fehlt komplett
   - Benötigt Kernel-Modul-Kompilierung oder Kernel-Update

## NÄCHSTE SCHRITTE (NICHT DURCHGEFÜHRT):

1. **Audio:**
   - Kernel-Device-Tree direkt modifizieren (nicht via Overlay)
   - Oder: I2C Bus 13 via udev/systemd manuell konfigurieren
   - Oder: Custom Kernel mit korrektem Overlay kompilieren

2. **FT6236:**
   - Kernel-Modul kompilieren
   - Oder: Kernel-Update mit FT6236 Support

## PROBLEME:

- **Overlay-Ladung:** Overlay wird kompiliert, aber nicht geladen oder erstellt keine Nodes
- **Bus 13:** Keine einfache Möglichkeit, Bus 13 in Overlays zu targeten
- **Kernel-Module:** FT6236 Modul fehlt

