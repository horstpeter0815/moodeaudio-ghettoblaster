# Pipeline Cockpit - Anleitung

## Dateien:

1. **pipeline_cockpit.html** - Grafisches Dashboard
2. **STANDARD_TEST_SUITE.md** - Standard-Test Definitionen
3. **AUDIO_VIDEO_PIPELINE_PLAN.md** - Detaillierter Plan
4. **PIPELINE_STATUS_TRACKER.md** - Status-Tracker

## Cockpit öffnen:

```bash
# Im Browser öffnen:
open pipeline_cockpit.html

# Oder direkt:
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome pipeline_cockpit.html
```

## Features:

### 1. Phasen-Übersicht:
- Jede Phase als Karte
- Status-Anzeige (🔴/🟠/🟢)
- Fortschritts-Balken
- Schritt-für-Schritt Liste

### 2. Gesamt-Fortschritt:
- Großer Fortschritts-Balken
- Prozent-Anzeige
- Schritt-Zähler

### 3. Test-Suite:
- Alle Tests aufgelistet
- Status pro Test
- GESPERRT bis Phasen fertig sind

## Status aktualisieren:

Status wird in `PIPELINE_STATUS_TRACKER.md` gepflegt und kann im Cockpit angezeigt werden.

## WICHTIG:

- Tests werden NUR ausgeführt wenn alle Phasen fertig sind
- Status wird manuell aktualisiert
- Cockpit zeigt aktuellen Stand

---

**Status:** Cockpit erstellt, bereit zur Nutzung

