# Device Tree Overlay Anpassung - Sicherheitsbewertung

## Option 2: Device Tree Overlay manuell anpassen

### Ist das Update sicher?

**JA, mit folgenden Vorsichtsmaßnahmen:**

### Sicherheitsmaßnahmen:

1. **Backup erstellen:**
   - Original Overlay-Datei wird nicht überschrieben
   - Backup wird erstellt: `/boot/firmware/overlays/vc4-kms-dsi-waveshare-panel.dtbo.backup`
   - Original bleibt erhalten

2. **Neue Overlay-Datei erstellen:**
   - Erstelle neue Datei: `vc4-kms-dsi-waveshare-panel-fixed.dtbo`
   - Original bleibt unverändert
   - Kann jederzeit zurückgesetzt werden

3. **Risiko-Minimierung:**
   - System kann nicht booten, wenn Overlay fehlerhaft
   - **LÖSUNG:** Original-Datei bleibt erhalten
   - Bei Problemen: Overlay in config.txt entfernen oder Original wiederherstellen

### Was wird gemacht:

1. **Overlay dekompilieren:**
   ```bash
   dtc -I dtb -O dts /boot/firmware/overlays/vc4-kms-dsi-waveshare-panel.dtbo > overlay.dts
   ```

2. **Dependency Cycle beheben:**
   - Problem: Panel hängt von DSI ab, DSI hängt von Panel ab
   - Lösung: Dependency-Ordnung anpassen

3. **Neues Overlay kompilieren:**
   ```bash
   dtc -I dts -O dtb overlay.dts > vc4-kms-dsi-waveshare-panel-fixed.dtbo
   ```

4. **Testen:**
   - Neue Overlay-Datei in config.txt verwenden
   - Bei Problemen: Original verwenden

### Risiko-Bewertung:

- **Niedrig:** Original bleibt erhalten, kann zurückgesetzt werden
- **Mittel:** System könnte nicht booten (aber Original-Datei bleibt)
- **Hoch:** Nur wenn Original überschrieben wird (wird NICHT gemacht)

### Empfehlung:

**SICHER** - Mit Backup und neuer Datei (nicht Original überschreiben)

