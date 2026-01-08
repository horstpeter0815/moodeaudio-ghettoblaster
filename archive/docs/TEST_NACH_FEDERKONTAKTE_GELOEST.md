# Test nach Lösen der Federkontakte

## Setup nach Hard Reset

### Hardware-Konfiguration:
- ✅ **DSI-Kabel verbunden** (für DSI I2C - i2c-10)
- ✅ **Federkontakte gelöst** (GPIO 3/5 nicht verbunden)
- ✅ **DIP-Switch auf I2C0** (für i2c-10, DSI I2C)

### Erwartetes Verhalten:
- Display sollte über **i2c-10** (DSI I2C) erreichbar sein
- **Kein Konflikt** mit i2c-1 (GPIO I2C) mehr
- Panel sollte initialisiert werden

## Test-Plan nach Hard Reset

### 1. I2C Bus Status prüfen
```bash
# i2c-10 sollte 0x45 (Panel) zeigen
i2cdetect -y 10

# i2c-1 sollte leer sein (keine Federkontakte)
i2cdetect -y 1
```

### 2. Panel-Initialisierung prüfen
```bash
# Panel-Device sollte existieren
ls -la /proc/device-tree/soc/i2c0mux/i2c@1/panel_disp1@45/

# Keine Dependency Cycles mehr?
dmesg | grep -i "dependency cycle"
```

### 3. Display-Status prüfen
```bash
# Framebuffer sollte existieren
ls -la /dev/fb*

# DRM Devices
ls -la /sys/class/drm/
```

### 4. Touchscreen-Status
```bash
# ws_touchscreen sollte NICHT binden
lsmod | grep ws_touchscreen
```

## Erwartete Ergebnisse

✅ **Erfolg:**
- i2c-10 zeigt 0x45 (Panel)
- Panel initialisiert
- Display zeigt Bild
- Keine Dependency Cycles

❌ **Wenn es nicht funktioniert:**
- Prüfe DIP-Switch Position (muss I2C0 sein)
- Prüfe DSI-Kabel-Verbindung
- Prüfe ob Overlay korrekt geladen ist

