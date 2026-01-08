# HDMI Display - Quick Reference

## Konfiguration (nur das was funktioniert)

### cmdline.txt
```
video=HDMI-A-2:400x1280M@60,rotate=90
```

### config.txt
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
hdmi_force_hotplug=1
hdmi_drive=2
```

### .xinitrc (Kritische Teile)
```bash
# Rotation IMMER setzen
DISPLAY=:0 xrandr --output HDMI-2 --rotate left

# Chromium mit --no-sandbox
chromium --no-sandbox \
    --app="http://localhost/" \
    --window-size="1280,400" \
    --disable-gpu \
    --kiosk &

# Touchscreen invertieren
xinput set-prop [ID] "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
```

## Wichtigste Punkte

1. **cmdline.txt:** `video=HDMI-A-2:400x1280M@60,rotate=90` (Portrait mit Rotation)
2. **xinitrc:** `xrandr --output HDMI-2 --rotate left` (Rotation zu Landscape)
3. **Chromium:** `--no-sandbox` (KRITISCH!)
4. **Chromium:** `--window-size="1280,400"` (explizit, nicht $SCREEN_RES)
5. **Touchscreen:** Matrix `-1 0 1, 0 -1 1, 0 0 1` (beide Achsen invertiert)

## Status: ✅ FUNKTIONIERT
