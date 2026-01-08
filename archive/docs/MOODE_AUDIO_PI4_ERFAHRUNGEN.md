# moOde Audio auf Raspberry Pi 4 - Vorherige Erfahrungen

## Zusammenfassung aller bisherigen Arbeiten

### Hardware-Setup
- **Raspberry Pi 4B**
- **Waveshare 7.9" DSI LCD Display**
- **HiFiBerry AMP100** (über GPIO I2C - i2c-1)
- **DSI-Kabel:** 15PIN FPC Kabel verbunden
- **DIP-Switch:** Auf "I2C0" (für i2c-10, DSI I2C)
- **IP-Adresse:** 192.168.178.122

## Wichtige Erkenntnisse aus vorherigen Sessions

### 1. I2C Bus Architektur (KRITISCH!)

**Zwei separate I2C-Busse:**
- **i2c-1:** GPIO I2C (Pins 3/5) - für **HiFiBerry DAC**
- **i2c-10:** DSI I2C (über DSI-Kabel) - für **Waveshare Display**
  - Panel Controller: 0x45
  - GT911 Touch: 0x14

**WICHTIG:**
- Beide Busse können gleichzeitig aktiv sein
- Kein Konflikt zwischen HiFiBerry und Display
- DIP-Switch muss auf "I2C0" stehen (nicht "I2C1"!)

### 2. Display-Konfiguration für moOde Audio

**config.txt (Pi4 Sektion):**
```
[pi4]
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,touchscreen-size-x=1280,touchscreen-size-y=400,disable_touch
# dtoverlay=vc4-kms-v3d-pi4,noaudio  ← DEAKTIVIERT!
```

**Allgemeine Einstellungen:**
```
display_auto_detect=0
hdmi_ignore_hotplug=1
dtparam=act_led_trigger=heartbeat
dtparam=i2c=on
dtoverlay=hifiberry-amp100,automute
```

**cmdline.txt:**
```
root=/dev/mmcblk0p2 rootwait console=tty5 systemd.show_status=0 net.ifnames=0
# KEIN video= Parameter!
```

### 3. Touchscreen-Größe Problem (GELÖST!)

**Problem:**
- Overlay setzte falsch: `touchscreen-size-x=4096, touchscreen-size-y=4096` (für 4K-TV!)
- Korrekte Werte: `touchscreen-size-x=1280, touchscreen-size-y=400` (für 7.9" Display)

**Lösung:**
- Parameter explizit in config.txt setzen
- `touchscreen-size-x=1280,touchscreen-size-y=400,disable_touch`

### 4. Overlay-Konfiguration (KRITISCH!)

**Fehler die vermieden werden müssen:**
- ❌ Overlay in `[all]` Sektion → FALSCH!
- ❌ `vc4-kms-v3d-pi4` aktiv → Konflikt!
- ❌ `display_auto_detect=1` → Überschreibt manuelle Konfiguration

**Richtig:**
- ✅ Overlay in `[pi4]` Sektion
- ✅ `vc4-kms-v3d-pi4` deaktiviert
- ✅ `display_auto_detect=0`

### 5. Bekannte Probleme

#### Problem 1: ws_touchscreen bindet an Panel
- `ws_touchscreen` bindet an 0x45 (Panel) statt 0x14 (Touchscreen)
- Blockiert Panel-Initialisierung
- Lösung: `disable_touch` setzen (funktioniert teilweise)

#### Problem 2: Dependency Cycles
- DSI ↔ Panel ↔ I2C ↔ CPRMAN
- Alle brauchen sich gegenseitig
- Kernel versucht aufzulösen, aber Panel bleibt uninitialisiert

#### Problem 3: I2C Bus 10 zeigt keine Devices
- Panel wird nicht initialisiert
- `i2cdetect -y 10` zeigt keine Devices
- Ursache: Dependency Cycles + ws_touchscreen Problem

### 6. moOde Audio spezifische Einstellungen

**Aus WAVESHARE_IMAGE_ANALYSIS.md:**
- moOde verwendet MPD + ALSA
- Kein PipeWire (wurde explizit ausgeschlossen)
- Display sollte für moOde UI verwendet werden

**Wichtige Unterschiede zu Waveshare Image:**
- Waveshare Image: `WS_xinchDSI_Screen` Overlay (veraltet)
- moOde: `vc4-kms-dsi-waveshare-panel` Overlay (aktuell)

### 7. Federkontakte (Spring Pins)

**Situation:**
- Pi sitzt direkt auf Display
- Federkontakte GPIO 3/5 sind physisch verbunden
- Das verbindet i2c-1 (GPIO I2C) mit Display

**Erkenntnis:**
- Federkontakte können gelöst werden (nicht nötig für DSI I2C)
- Display funktioniert über DSI-Kabel (i2c-10)
- HiFiBerry braucht i2c-1 (GPIO I2C)

## Konfiguration für moOde Audio Installation

### Schritt 1: moOde Audio installieren
- Standard moOde Audio Image für Pi 4 verwenden
- Nach Installation: Display-Konfiguration anpassen

### Schritt 2: config.txt anpassen
```
# Pi4 Sektion
[pi4]
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,touchscreen-size-x=1280,touchscreen-size-y=400,disable_touch
# dtoverlay=vc4-kms-v3d-pi4,noaudio  ← DEAKTIVIERT!

# Allgemeine Einstellungen
display_auto_detect=0
hdmi_ignore_hotplug=1
dtparam=i2c=on
dtoverlay=hifiberry-amp100,automute
dtparam=act_led_trigger=heartbeat
```

### Schritt 3: cmdline.txt anpassen
```
root=/dev/mmcblk0p2 rootwait console=tty5 systemd.show_status=0 net.ifnames=0
# KEIN video= Parameter!
```

### Schritt 4: Testen
```bash
# I2C Bus 10 prüfen
i2cdetect -y 10  # Sollte 0x45 zeigen

# Dependency Cycles prüfen
dmesg | grep -i "dependency cycle"

# Display-Status prüfen
ls /sys/class/drm/
ls /dev/fb*
```

## Wichtige Dateien

- `PI4_WAVESHARE_ERKENNTNISSE.md` - Alle Erkenntnisse von heute
- `WAVESHARE_DISPLAY_PROBLEM.md` - Problem-Dokumentation
- `WAVESHARE_OVERLAY_ANALYSE.md` - Overlay-Analyse
- `waveshare-overlay-decompiled.dts` - Dekompiliertes Overlay

## Zusammenfassung für moOde Audio Setup

**Was funktioniert:**
- ✅ I2C Bus Architektur verstanden (i2c-1 für HiFiBerry, i2c-10 für Display)
- ✅ Touchscreen-Größen korrigiert (1280x400)
- ✅ Overlay-Konfiguration korrekt (in [pi4] Sektion)
- ✅ vc4-kms-v3d-pi4 deaktiviert

**Was noch problematisch ist:**
- ❌ ws_touchscreen bindet an falsche Adresse
- ❌ Dependency Cycles blockieren Initialisierung
- ❌ Panel wird nicht initialisiert → kein Bild

**Nächste Schritte:**
1. moOde Audio installieren
2. config.txt mit korrekten Werten anpassen
3. Testen ob Display funktioniert
4. Falls nicht: ws_touchscreen Problem angehen

