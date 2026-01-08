# Raspberry Pi 4 + Waveshare 7.9" DSI Display - Erkenntnisse

## Hardware-Konfiguration

### Display-Verbindung:
- **DSI-Kabel:** 15PIN FPC Kabel (nicht DSI-Cable-12cm!)
- **DIP-Switch:** Muss auf **"I2C0"** stehen (für i2c-10, DSI I2C)
- **Federkontakte:** GPIO 3/5 können verbunden sein (Pi sitzt auf Display), aber nicht nötig für DSI I2C

### I2C Bus Architektur:
- **i2c-1:** GPIO I2C (Pins 3/5) - für HiFiBerry
- **i2c-10:** DSI I2C (über DSI-Kabel) - für Waveshare Display
  - Panel Controller: **0x45**
  - GT911 Touch: **0x14**

## Wichtige Erkenntnisse

### 1. Overlay-Konfiguration

**Korrekte config.txt für Pi4:**
```
[pi4]
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,touchscreen-size-x=1280,touchscreen-size-y=400,disable_touch
# dtoverlay=vc4-kms-v3d-pi4,noaudio  ← DEAKTIVIERT!
```

**WICHTIG:**
- Overlay muss in `[pi4]` Sektion sein, NICHT in `[all]`!
- `vc4-kms-v3d-pi4` muss deaktiviert sein (Konflikt!)
- `display_auto_detect=0` setzen
- `hdmi_ignore_hotplug=1` setzen

### 2. Touchscreen-Größe Problem

**KRITISCH:** Das Overlay setzt falsche Touchscreen-Größen!
- **FALSCH:** `touchscreen-size-x=4096, touchscreen-size-y=4096` (für 4K-TV!)
- **RICHTIG:** `touchscreen-size-x=1280, touchscreen-size-y=400` (für 7.9" Display)

**7.9" Display:**
- Display-Auflösung: **1280x400**
- Touchscreen-Größe: **1280x400** (nicht 4096x4096!)

### 3. Hardcodierte Werte im Overlay

**Kann NICHT geändert werden:**
- I2C-Adresse Panel: **0x45** (hardcodiert)
- I2C-Adresse Touchscreen: **0x14** (hardcodiert)
- I2C Bus: **i2c_csi_dsi** (i2c-10) - hardcodiert
- DSI-Interface: **dsi1** (DSI-1) - hardcodiert

**Kann überschrieben werden:**
- `touchscreen-size-x` und `touchscreen-size-y` (via Parameter)
- `disable_touch` (deaktiviert goodix@14)

### 4. Dependency Cycles

**Problem:** Dependency Cycles im Overlay-Design:
- DSI ↔ Panel ↔ I2C ↔ CPRMAN
- Alle brauchen sich gegenseitig zur Initialisierung
- Kernel versucht aufzulösen, aber Panel bleibt uninitialisiert

**Symptome:**
- `dmesg` zeigt: "Fixed dependency cycle(s)"
- Panel-Device existiert, aber wird nicht initialisiert
- I2C Bus 10 zeigt keine Devices (0x45 fehlt)

### 5. ws_touchscreen Problem

**Kritisches Problem:**
- `ws_touchscreen` bindet an **0x45** (Panel-Adresse) statt 0x14 (Touchscreen)
- Das blockiert die Panel-Initialisierung
- `disable_touch` deaktiviert nur `goodix@14`, aber `ws_touchscreen` bindet trotzdem

**Lösungsversuche:**
- `disable_touch` Parameter → funktioniert nicht vollständig
- Blacklist `ws_touchscreen` → Modul wird trotzdem geladen
- Manuelles Unbind → temporär, aber nicht dauerhaft

### 6. Command Line Parameter

**cmdline.txt:**
- **KEIN** `video=DSI-1:1280x400@60` Parameter nötig!
- Overlay übernimmt die Konfiguration
- Command-Line-Parameter können Konflikte verursachen

### 7. i2c-gpio Overlay

**WICHTIG:**
- `dtoverlay=i2c-gpio` verwendet GPIO-Pins
- Display braucht nur DSI-Kabel, keine GPIO-Verbindung
- i2c-gpio kann Konflikte verursachen → auskommentieren wenn nicht benötigt

## Konfiguration für moOde Audio

### Minimal config.txt:
```
# Pi4 Sektion
[pi4]
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,touchscreen-size-x=1280,touchscreen-size-y=400,disable_touch
# dtoverlay=vc4-kms-v3d-pi4,noaudio  ← DEAKTIVIERT!

# Allgemeine Einstellungen
display_auto_detect=0
hdmi_ignore_hotplug=1
dtparam=act_led_trigger=heartbeat
```

### cmdline.txt:
```
root=/dev/mmcblk0p2 rootwait console=tty5 systemd.show_status=0 net.ifnames=0
# KEIN video= Parameter!
```

## Bekannte Probleme & Lösungsansätze

### Problem 1: Display zeigt kein Bild
**Ursachen:**
- Dependency Cycles blockieren Initialisierung
- ws_touchscreen bindet an Panel (0x45)
- Falsche Touchscreen-Größen (4096x4096 statt 1280x400)

**Lösungsansätze:**
1. Touchscreen-Größen korrigieren (✓ gemacht)
2. `vc4-kms-v3d-pi4` deaktivieren (✓ gemacht)
3. Overlay in `[pi4]` Sektion (✓ gemacht)
4. `disable_touch` setzen (✓ gemacht, aber ws_touchscreen bindet trotzdem)

### Problem 2: I2C Bus 10 zeigt keine Devices
**Ursachen:**
- Panel wird nicht initialisiert
- ws_touchscreen blockiert Panel
- Dependency Cycles verhindern I2C-Kommunikation

**Diagnose:**
```bash
i2cdetect -y 10  # Sollte 0x45 zeigen, zeigt aber nichts
```

### Problem 3: ws_touchscreen bindet trotz disable_touch
**Ursache:**
- `disable_touch` deaktiviert nur `goodix@14`
- `ws_touchscreen` bindet trotzdem an Panel (0x45)
- Overlay-Design-Problem

**Mögliche Lösungen:**
- Overlay modifizieren (komplex)
- Kernel-Modul blacklisten (funktioniert nicht zuverlässig)
- Manuelles Unbind nach Boot (Workaround)

## Nächste Schritte für moOde Audio

1. **moOde Audio installieren** (wie geplant)
2. **Display-Konfiguration anpassen:**
   - `config.txt` mit korrekten Werten
   - `cmdline.txt` ohne video-Parameter
3. **Testen:**
   - I2C Bus 10 prüfen (`i2cdetect -y 10`)
   - Dependency Cycles prüfen (`dmesg | grep dependency`)
   - Display-Status prüfen (`ls /sys/class/drm/`)
4. **Falls Problem bleibt:**
   - ws_touchscreen manuell unbinden
   - Overlay-Parameter weiter anpassen
   - Kernel-Logs analysieren

## Wichtige Dateien

- `waveshare-overlay-decompiled.dts` - Dekompiliertes Overlay
- `WAVESHARE_OVERLAY_ANALYSE.md` - Detaillierte Overlay-Analyse
- `WAVESHARE_DISPLAY_PROBLEM.md` - Problem-Dokumentation
- `TOUCHSCREEN_SIZE_PROBLEM.md` - Touchscreen-Größen-Problem

## Zusammenfassung

**Was funktioniert:**
- ✅ Panel-Device wird im Device Tree erstellt
- ✅ Overlay wird geladen
- ✅ Panel-Modul (`panel_waveshare_dsi`) wird geladen
- ✅ Konfiguration ist korrekt

**Was funktioniert nicht:**
- ❌ Panel wird nicht initialisiert
- ❌ I2C-Kommunikation schlägt fehl (Timeout -110)
- ❌ ws_touchscreen bindet an falsche Adresse (0x45)
- ❌ Dependency Cycles blockieren Initialisierung
- ❌ Display zeigt kein Bild

**Hauptproblem:**
Das Overlay-Design hat Dependency Cycles und ws_touchscreen bindet an die falsche Adresse. Das verhindert die Panel-Initialisierung.

