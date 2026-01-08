# Raspberry Pi 4 vs Pi 5 - Config.txt Unterschiede

**Erstellt:** 25. November 2024  
**Kritisch:** Waveshare Support config.txt war für Pi 5, nicht Pi 4!

---

## Wichtigste Unterschiede

### VideoCore KMS Overlays

**Raspberry Pi 4:**
```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
```

**Raspberry Pi 5:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
```

**❌ FALSCH (generisch, funktioniert auf beiden, aber nicht optimal):**
```ini
[all]
dtoverlay=vc4-kms-v3d
```

---

## Hardware-Unterschiede

### DSI Interface

| Feature | Pi 4 | Pi 5 |
|---------|------|------|
| DSI Lanes | 2-lane | 4-lane |
| DSI Connector | 1x 2-lane | 1x 4-lane |
| DSI Overlay Flag | `dsi0` oder `dsi1` | `dsi0` oder `dsi1` |

**Wichtig:** Pi 4 hat nur DSI-1 (2-lane), Pi 5 hat DSI-1 (4-lane)

---

### I2C Bus Architektur

**Raspberry Pi 4:**
- `i2c-1`: GPIO I2C (VideoCore verwaltet)
- `i2c-10`: DSI/CSI I2C (VideoCore verwaltet)

**Raspberry Pi 5:**
- `i2c-1`: RP1 I2C (RP1 Controller verwaltet)
- `i2c-6`: RP1 I2C (alternativ)
- `i2c-10`: DSI/CSI I2C (VideoCore verwaltet)

**Wichtig:** Pi 5 verwendet RP1 Controller für GPIO I2C, Pi 4 verwendet VideoCore

---

### HDMI

| Feature | Pi 4 | Pi 5 |
|---------|------|------|
| HDMI Version | 2.0 | 2.1 |
| Max Resolution | 4K@60Hz | 4K@120Hz |
| Parameter | `hdmi_enable_4kp60=1` | `hdmi_enable_4kp60=1` |

---

## Waveshare Display Konfiguration

### Pi 4 (KORREKT)

```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch

[all]
display_auto_detect=0
hdmi_ignore_hotplug=1
dtparam=i2c_arm=on
dtparam=i2c_vc=on
```

### Pi 5 (KORREKT)

```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch

[all]
display_auto_detect=0
hdmi_ignore_hotplug=1
dtparam=i2c_arm=on
dtparam=i2c_vc=on
```

---

## Problem: Waveshare Support Config.txt

Die Datei `config.txt by waveshare support.txt` enthält:

```ini
[all]
dtoverlay=vc4-kms-v3d
```

**Problem:**
- `vc4-kms-v3d` ist generisch und funktioniert auf beiden
- Aber: Nicht optimal für Pi 4 oder Pi 5
- Pi 4 sollte `vc4-kms-v3d-pi4` verwenden
- Pi 5 sollte `vc4-kms-v3d-pi5` verwenden

**Lösung:**
- Für Pi 4: `dtoverlay=vc4-kms-v3d-pi4,noaudio` in `[pi4]` Sektion
- Für Pi 5: `dtoverlay=vc4-kms-v3d-pi5,noaudio` in `[pi5]` Sektion

---

## Aktuelle Situation

**Pi-Modell:** Raspberry Pi 4 Model B Rev 1.5

**Aktuelle Config (KORREKT für Pi 4):**
```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```

**Status:** ✅ Konfiguration ist korrekt für Pi 4!

---

## Weitere Unterschiede

### RP1 Controller (nur Pi 5)

Pi 5 hat einen dedizierten RP1 I/O-Controller:
- Verwaltet GPIO, I2C, SPI, UART, PWM
- Entlastet die CPU
- Separate I2C Busse über RP1

Pi 4 hat keinen RP1 Controller, I/O wird direkt von VideoCore/CPU verwaltet.

---

### PCIe (nur Pi 5)

Pi 5 hat PCIe 2.0 x1 Support:
```ini
dtparam=pciex1
dtparam=pciex1_gen=3
```

Pi 4 hat keinen PCIe Support.

---

### NVMe (nur Pi 5)

Pi 5 unterstützt NVMe SSDs über M.2:
- Keine config.txt Parameter nötig
- Wird über Hardware-Adapter aktiviert

Pi 4 unterstützt kein NVMe.

---

## Zusammenfassung

**Für Pi 4:**
- ✅ `dtoverlay=vc4-kms-v3d-pi4,noaudio`
- ✅ 2-lane DSI
- ✅ HDMI 2.0 (4K@60Hz)

**Für Pi 5:**
- ✅ `dtoverlay=vc4-kms-v3d-pi5,noaudio`
- ✅ 4-lane DSI
- ✅ HDMI 2.1 (4K@120Hz)
- ✅ RP1 Controller
- ✅ PCIe Support

**Wichtig:** Waveshare Support config.txt war für Pi 5, aber wir haben Pi 4! Die aktuelle Config ist korrekt angepasst.

