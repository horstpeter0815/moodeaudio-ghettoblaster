# Funktionierende Pi 5 Config wiederherstellen

## Situation

**Vor einigen Tagen:**
- ✅ Pi 5 funktionierte komplett
- ✅ Display (1280x400) funktionierte
- ✅ Touchscreen funktionierte  
- ✅ Sound funktionierte
- ✅ Config wurde GESPEICHERT vor Peppy-Installation

**Dann:**
- ❌ Peppy wurde installiert
- ❌ Alles kaputt gegangen
- ❌ Display funktioniert nicht mehr
- ❌ Touchscreen funktioniert nicht mehr

## Gefundene funktionierende Configs

### 1. config_optimal_waveshare.txt (für Pi 4, aber ähnlich)
```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio

[all]
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch,i2c1
disable_fw_kms_setup=0
```

### 2. EXACT_WAVESHARE_CONFIG.md (Waveshare Wiki)
```ini
[all]
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```

## Funktionierende Config für Pi 5 (DSI0/I2C0)

**Basierend auf funktionierenden Configs und Pi 5 Unterschieden:**

```ini
[pi5]
hdmi_enable_4kp60=0

[all]
# Basis-KMS (True KMS für Pi 5)
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

# Wichtig: Firmware-KMS aktivieren
disable_fw_kms_setup=0

# Allgemeine Einstellungen
arm_64bit=1
arm_boost=1
disable_splash=1
disable_overscan=1
```

## Restore-Schritte

1. **Peppy entfernen/deaktivieren**
2. **Config.txt zurücksetzen** (siehe oben)
3. **Reboot**
4. **Testen**

---

**Status:** Funktionierende Config identifiziert. Bereit für Restore.

