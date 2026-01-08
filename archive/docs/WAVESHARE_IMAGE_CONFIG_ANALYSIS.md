# Waveshare Pre-installed Image - Config Analyse

## Gefundene Konfiguration

### Wichtigste Erkenntnisse:

1. **Anderes Overlay-System:**
   - **Waveshare Image:** `WS_xinchDSI_Screen` + `WS_xinchDSI_Touch`
   - **Aktuelles System:** `vc4-kms-dsi-waveshare-panel`
   - **Unterschied:** Altes Waveshare Driver-System vs. neues KMS-System

2. **7.9" Display Konfiguration (auskommentiert):**
   ```
   #7.9inch DSI LCD use：
   #dtoverlay=WS_xinchDSI_Screen,SCREEN_type=5,I2C_bus=10
   #dtoverlay=WS_xinchDSI_Touch,invertedx,invertedy,I2C_bus=10
   ```

3. **Aktive Konfiguration im Image:**
   - `dtoverlay=WS_xinchDSI_Screen,SCREEN_type=8,I2C_bus=10` (8" Display)
   - `dtoverlay=WS_xinchDSI_Touch,invertedx,swappedxy,I2C_bus=10`

4. **Wichtige Parameter:**
   - `display_auto_detect=1` (aktiviert!)
   - `ignore_lcd=1`
   - `dtparam=i2c_vc=on`
   - `dtparam=i2c_arm=on`
   - `dtoverlay=vc4-kms-v3d`

## Problem

Das Waveshare Image verwendet das **alte Waveshare Driver-System** (für Buster/Bullseye), das auf Trixie nicht verfügbar ist. Das neue System verwendet `vc4-kms-dsi-waveshare-panel`, was ein anderes Overlay-System ist.

## Lösung

Da das alte System auf Trixie nicht verfügbar ist, müssen wir beim neuen System bleiben und die Konfiguration optimieren.

## Nächste Schritte

1. Prüfe, ob `WS_xinchDSI_Screen` Overlays auf Trixie verfügbar sind
2. Falls nicht: Optimiere die `vc4-kms-dsi-waveshare-panel` Konfiguration
3. Teste mit `display_auto_detect=1` (wie im Waveshare Image)

