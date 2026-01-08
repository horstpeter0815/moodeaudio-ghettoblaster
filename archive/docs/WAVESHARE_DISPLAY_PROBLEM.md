# Waveshare 7.9" Display Problem - Diagnose

## Aktueller Status
- ✅ Grüne LED leuchtet = Display hat Strom
- ❌ Kein Bild = Panel wird nicht initialisiert
- ❌ I2C Timeout-Fehler (-110) = Hardware antwortet nicht auf I2C Bus 10
- ❌ ws_touchscreen Treiber blockiert Panel auf Adresse 0x45

## Konfiguration (aus PDF)

### Korrekte config.txt:
```
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,rotation=90
# KEIN i2c1 Parameter!
# KEIN dtparam=i2c_vc=on (wird automatisch aktiviert)
```

### DIP-Switch Positionen:
- **"I2C0"** = I2C Bus 10 (DSI I2C) ← **RICHTIG für diese Setup**
- **"I2C1"** = I2C Bus 1 (GPIO I2C) ← FALSCH (würde mit HiFiBerry kollidieren)

### I2C Bus Architektur:
- **i2c-1**: GPIO I2C (Pins 3/5) - für HiFiBerry
- **i2c-10**: DSI I2C (über DSI-Kabel, KEINE GPIO-Pins!) - für Waveshare Display
  - Panel Controller: 0x45
  - GT911 Touch: 0x14
  - **WICHTIG:** Pi sitzt direkt auf Display - Federkontakte (spring pins) GPIO 3/5 sind physisch verbunden!

## Bekannte Probleme

### Problem 1: ws_touchscreen bindet sich an Panel
- Der ws_touchscreen Treiber bindet sich an 0x45 (Panel)
- Das Panel sollte vom panel_waveshare_dsi Treiber verwaltet werden
- Beide sind Teil des gleichen Moduls (panel_waveshare_dsi)

### Problem 2: I2C Timeout (-110)
- Hardware antwortet nicht auf I2C Bus 10
- Mögliche Ursachen:
  1. DIP-Switch steht falsch (trotz Umstellung)
  2. DSI-Kabel nicht richtig angeschlossen
  3. Panel-Hardware-Problem
  4. I2C Bus 10 wird nicht richtig aktiviert

## Diagnose-Schritte

1. **DIP-Switch physisch prüfen**
   - Display umdrehen
   - DIP-Switch Position sichtbar machen
   - Muss auf "I2C0" stehen

2. **DSI-Kabel prüfen**
   - Kabel richtig eingesteckt?
   - Alle Pins verbunden?

3. **I2C Bus 10 prüfen**
   ```bash
   sudo i2cdetect -y 10
   # Sollte 0x45 und 0x14 zeigen (oder "UU" wenn Treiber aktiv)
   ```

4. **Panel-Treiber Status**
   ```bash
   ls -la /sys/bus/i2c/devices/10-0045/driver
   cat /sys/bus/i2c/devices/10-0045/driver/name
   ```

5. **DSI Connector Status**
   ```bash
   ls /sys/class/drm/card0-DSI-*
   cat /sys/class/drm/card0-DSI-1/status
   ```

## Lösung-Strategie

Wenn DIP-Switch korrekt ist und Kabel richtig:
1. Panel-Treiber neu binden
2. DSI-Connector prüfen
3. Hardware-Problem ausschließen

