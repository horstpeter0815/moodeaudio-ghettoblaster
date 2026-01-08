# Touchscreen-Größe Problem

## Problem identifiziert!

### Falsche Werte im Overlay:

Das `7_9_inch` Parameter im Overlay setzt:
- `touchscreen-size-x = 4096` ❌
- `touchscreen-size-y = 4096` ❌

### Das ist FALSCH!

**4096x4096 ist für 4K-TV (3840x2160), nicht für 7.9" Display!**

### Korrekte Werte für 7.9" Display:

- **Display-Auflösung:** 1280x400
- **Touchscreen-Größe sollte sein:**
  - `touchscreen-size-x = 1280` (nicht 4096!)
  - `touchscreen-size-y = 400` (nicht 4096!)

## Warum ist das ein Problem?

1. **Falsche Touchscreen-Kalibrierung**
   - Touchscreen-Driver erwartet 4096x4096
   - Display hat nur 1280x400
   - → Touchscreen kann nicht richtig kalibriert werden

2. **Initialisierungsproblem**
   - Touchscreen-Driver versucht, 4096x4096 zu initialisieren
   - Hardware unterstützt das nicht
   - → Initialisierung schlägt fehl

3. **Dependency Cycle**
   - Falsche Touchscreen-Werte können Dependency Cycles verstärken
   - Touchscreen-Driver blockiert Panel-Initialisierung

## Lösung

### Option 1: Touchscreen-Parameter überschreiben

In `config.txt`:
```
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,touchscreen-size-x=1280,touchscreen-size-y=400,disable_touch
```

### Option 2: Touchscreen komplett deaktivieren

```
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch
```

**Hinweis:** `disable_touch` ist bereits gesetzt, aber die falschen Werte werden trotzdem im Overlay gesetzt!

## Nächster Schritt

Teste mit korrekten Touchscreen-Größen:
- `touchscreen-size-x=1280`
- `touchscreen-size-y=400`

Oder Touchscreen komplett deaktivieren, wenn nicht benötigt.

