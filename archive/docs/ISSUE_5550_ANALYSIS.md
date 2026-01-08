# GitHub Issue #5550 Analyse - Waveshare 7.9" DSI LCD

## Issue Übersicht
- **Titel:** Waveshare 7.9" DSI not working android pi4
- **Status:** Closed (2025-09-11)
- **Link:** https://github.com/raspberrypi/linux/issues/5550

## Ursprüngliches Problem
- **Kernel:** 6.1.31
- **OS:** Raspberry Pi OS (neueste Version)
- **Symptome:**
  - Display bleibt aus, LED blinkt
  - Mit `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch` funktioniert es NICHT
  - **ABER:** Funktioniert mit Android (LineageOS20)!

## WICHTIGE LÖSUNG (Kommentar von ilarrain, 2023-08-05)

**Problem gelöst mit Raspberry Pi OS (Kernel 6.1.42):**

> "I have the same panel, editing the overlay did the trick. The default values were incorrect for 'touchscreen-size-x:0', 'touchscreen-size-y:0', 'touchscreen-inverted-y', and 'touchscreen-swapped-x-y'."

### Lösung:
1. **Overlay-Parameter korrigieren:**
   - `touchscreen-size-x` und `touchscreen-size-y` waren auf 0 (falsch)
   - `touchscreen-inverted-y` und `touchscreen-swapped-x-y` waren falsch

2. **Workaround:**
   - `sizex=4096,sizey=4096` setzen
   - Oder modifiziertes Overlay mit korrekten Defaults kompilieren

3. **Erfolgreich getestet mit:**
   - Raspberry Pi OS (Stock)
   - Kernel 6.1.42-v8+ (Juli 2023)

## Relevanz für unser Problem

### Ähnlichkeiten:
- ✅ Gleiches Display: Waveshare 7.9" DSI LCD
- ✅ Gleiche Symptome: Display bleibt aus, LED blinkt
- ✅ Gleiche Konfiguration: `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch`

### Unterschiede:
- ❌ Unser Kernel: 6.12.47 (Trixie) - viel neuer
- ✅ Issue Kernel: 6.1.31/6.1.42 (2023) - älter

### Mögliche Lösungen:

1. **Overlay-Parameter anpassen:**
   ```bash
   dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,touchscreen-size-x=4096,touchscreen-size-y=4096
   ```

2. **Touchscreen-Parameter explizit setzen:**
   - `touchscreen-inverted-y` prüfen/korrigieren
   - `touchscreen-swapped-x-y` prüfen/korrigieren

3. **Kernel-Downgrade:**
   - Auf Kernel 6.1.42 oder ähnlich downgraden (wie in Issue getestet)

## Nächste Schritte

1. **Overlay-Parameter testen:**
   - `touchscreen-size-x=4096,touchscreen-size-y=4096` hinzufügen
   - Reboot und prüfen

2. **Kernel-Version prüfen:**
   - Issue zeigt: Kernel 6.1.42 funktioniert
   - Unser Kernel 6.12.47 ist viel neuer - möglicherweise Inkompatibilität

3. **Kombinierter Ansatz:**
   - Overlay-Parameter anpassen
   - Falls das nicht hilft: Kernel-Downgrade erwägen

## Referenzen
- Issue: https://github.com/raspberrypi/linux/issues/5550
- Kommentar mit Lösung: https://github.com/raspberrypi/linux/issues/5550#issuecomment-1666592260
- Modifiziertes Overlay: https://drive.google.com/file/d/1vxbMmwprV20rWj2UMmCCoejJhksR0Og8/view

