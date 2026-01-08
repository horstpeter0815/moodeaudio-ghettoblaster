# Peppy Analysis und Restore-Plan

## Situation

**Vor einigen Tagen:**
- ✅ Pi 5 funktionierte komplett
- ✅ Display lief (1280x400)
- ✅ Touchscreen funktionierte
- ✅ Alles war gut

**Dann:**
- ❌ Peppy wurde installiert
- ❌ Peppy hat alles kaputt gemacht
- ❌ Display funktioniert nicht mehr
- ❌ Touchscreen funktioniert nicht mehr

## Was ist Peppy?

**Peppy** ist vermutlich ein Moode Audio Plugin für:
- Visualisierung (Spectrum Analyzer, VU Meter)
- Display-Management
- Touchscreen-Steuerung

**Peppy könnte geändert haben:**
- Config.txt (Display-Einstellungen)
- X11/xinitrc (Display-Manager)
- Systemd Services (Display-Services)
- Python-Scripts (Display-Treiber)
- Framebuffer-Konfiguration

## Gefundene funktionierende Configs

### 1. config_optimal_waveshare.txt (Pi 4)
```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio

[all]
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch,i2c1
disable_fw_kms_setup=0
```

### 2. EXACT_WAVESHARE_CONFIG.md
```ini
[all]
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```

## Restore-Plan für Pi 5

### Schritt 1: Peppy entfernen/deaktivieren

```bash
# Prüfe ob Peppy installiert ist
systemctl list-units | grep -i peppy
ls -la /opt/peppy* 2>/dev/null
ls -la /home/andre/peppy* 2>/dev/null

# Peppy Services stoppen
sudo systemctl stop peppy*.service 2>/dev/null
sudo systemctl disable peppy*.service 2>/dev/null

# Peppy aus Moode entfernen (falls Plugin)
# Über Moode Web-UI: Settings → Extensions → Peppy deaktivieren
```

### Schritt 2: Config.txt zurücksetzen

**Für Pi 5 mit DSI0/I2C0:**

```ini
[pi5]
hdmi_enable_4kp60=0

[all]
# Basis-KMS
dtoverlay=vc4-kms-v3d

# Waveshare Panel - DSI0/I2C0
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0

# I2C
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000

# HDMI deaktivieren
hdmi_ignore_hotplug=1
display_auto_detect=0
hdmi_force_hotplug=0
hdmi_blanking=1

# Framebuffer
fbcon=map=1

# Wichtig
disable_fw_kms_setup=0
```

### Schritt 3: X11/xinitrc prüfen

```bash
# Prüfe ob Peppy xinitrc geändert hat
cat /home/andre/.xinitrc
# Sollte Moode-Standard sein, nicht Peppy-spezifisch

# Falls Peppy-Änderungen vorhanden:
# Zurück zu Moode-Standard
```

### Schritt 4: Systemd Services prüfen

```bash
# Prüfe alle Display-bezogenen Services
systemctl list-units | grep -E 'display|framebuffer|peppy'

# Deaktiviere Peppy-Services
sudo systemctl disable peppy*.service
```

### Schritt 5: Python-Scripts prüfen

```bash
# Prüfe ob Peppy Python-Scripts installiert hat
find /home/andre -name "*peppy*" -o -name "*Peppy*"
find /opt -name "*peppy*" -o -name "*Peppy*"

# Falls gefunden: Backup und entfernen
```

## Erwartetes Ergebnis nach Restore

1. ✅ Config.txt wie vor Peppy
2. ✅ Keine Peppy-Services aktiv
3. ✅ Keine Peppy-Scripts laufen
4. ✅ Display funktioniert wieder
5. ✅ Touchscreen funktioniert wieder

## Nächste Schritte

1. **Prüfe aktuellen Zustand** auf beiden Pi 5
2. **Identifiziere Peppy-Änderungen**
3. **Entferne/Deaktiviere Peppy**
4. **Stelle funktionierende Config wieder her**
5. **Reboot und Test**

---

**Status:** Bereit für Analyse und Restore. Warte auf beide Pi 5.

