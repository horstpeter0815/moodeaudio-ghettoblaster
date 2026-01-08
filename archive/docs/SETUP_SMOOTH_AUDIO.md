# SETUP SMOOTH AUDIO (Zweites System)

## VORBEREITUNG:
- Smooth Audio Image auf SD-Karte gebrannt
- Raspberry Pi 5 mit AMP100
- GPIO 14 zu Reset-Pin gelötet (wie Ghettoblaster)

## KONFIGURATION (wie Ghettoblaster):

### 1. DISPLAY:
- Landscape Mode
- Touchscreen aktiviert (FT6236)
- Chromium in Kiosk-Mode

### 2. AUDIO:
- AMP100 mit GPIO14 Reset
- Overlay: `hifiberry-amp100-pi5-gpio14`
- I2C Bus 13 (RP1 Controller)

### 3. SYSTEM:
- moOde Audio Player
- MPD konfiguriert
- PeppyMeter (falls gewünscht)

## SCHRITTE:
1. SSH-Verbindung herstellen
2. Display konfigurieren
3. Touchscreen aktivieren
4. Audio konfigurieren (Overlay)
5. Testen und dokumentieren

