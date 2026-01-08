# Waveshare 7.9" DSI LCD - Detaillierte Analyse

## Hardware-Verbindung für Pi4B

**WICHTIG:**
1. **15PIN FPC Kabel** verwenden (nicht DSI-Cable-12cm - das ist nur für Pi5/CM5/CM4/CM3+/CM3)
2. DSI-Interface des Displays mit DSI-Interface des Raspberry Pi Boards verbinden
3. Raspberry Pi mit Rückseite nach unten auf das Display-Board installieren

## Software-Setting für Bookworm und Bullseye System

Laut Waveshare Wiki:

**Schritt 2:** Nach dem Flashen des Images, die `config.txt` Datei im Root-Verzeichnis der TF-Karte öffnen und **am Ende** folgenden Code hinzufügen:

```
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```

**WICHTIGE ERKENNTNISSE:**

1. **KEINE rotation Parameter** in der Basis-Konfiguration erwähnt
2. **KEINE disable_touch Parameter** in der Basis-Konfiguration erwähnt
3. **Nur:** `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch`

## Disable Touch (separater Abschnitt)

Laut Waveshare Wiki gibt es einen **separaten Abschnitt** "Disable Touch":
- Am Ende der config.txt Datei hinzufügen
- Nach dem Hinzufügen muss neu gestartet werden

## Aktuelle Konfiguration vs. Waveshare Empfehlung

### Aktuell:
```
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch
```

### Waveshare Basis-Empfehlung:
```
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```

## Mögliche Probleme

1. **disable_touch Parameter** könnte die Panel-Initialisierung stören
2. **rotation Parameter** fehlt in der Basis-Konfiguration - könnte aber für 90° Rotation benötigt werden
3. **Hardware-Verbindung** muss mit 15PIN FPC Kabel erfolgen (nicht DSI-Cable-12cm)

## Nächste Schritte

1. **Basis-Konfiguration testen:** Nur `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch` ohne disable_touch
2. **Hardware-Verbindung prüfen:** 15PIN FPC Kabel korrekt angeschlossen?
3. **DIP-Switches prüfen:** Auf I2C0 (entspricht /dev/i2c-10)

