# Waveshare Image Analyse

## ✅ WICHTIGE UNTERSCHIEDE zum Moode Setup:

### Config.txt:
**Waveshare Image:**
```
display_auto_detect=1                    ← AKTIV!
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch    ← OHNE rotation=90!
dtparam=i2c_arm=on
# KEIN dtparam=i2c_vc=on
```

**Unser Moode Setup:**
```
display_auto_detect=0                    ← DEAKTIVIERT
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,rotation=90
dtparam=i2c_vc=on
```

### Cmdline.txt:
**Waveshare Image:**
```
video=DSI-1:1280x400@60    ← OHNE rotate=90, OHNE fbcon=rotate:1
```

**Unser Moode Setup:**
```
video=DSI-1:400x1280M@60,rotate=90 fbcon=rotate:1
```

## 🔍 ERKENNTNISSE:

1. **display_auto_detect=1** funktioniert auf dem Waveshare-Image!
2. **KEINE Rotation** in config.txt oder cmdline.txt
3. **Resolution 1280x400** (landscape) statt 400x1280 (portrait)
4. **Gleicher ws_touchscreen Treiber** - aber Display funktioniert trotzdem
5. **Gleiche Device Tree Dependency Cycles** - aber kein Problem

## 💡 LÖSUNG für Moode:

Das Problem könnte sein:
- **Rotation=90** in config.txt könnte das Panel-Initialisierung stören
- **400x1280 Resolution** könnte falsch sein
- **fbcon=rotate:1** könnte nicht benötigt werden

## 🎯 NÄCHSTE SCHRITTE:

1. Entferne `rotation=90` aus config.txt
2. Ändere cmdline.txt zu `video=DSI-1:1280x400@60` (ohne rotate, ohne fbcon)
3. Setze `display_auto_detect=1` zurück
4. Entferne `dtparam=i2c_vc=on` (nicht im Waveshare Image)

