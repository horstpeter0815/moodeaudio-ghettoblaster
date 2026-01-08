# moOde Audio - Waveshare Display Fix

## Problem
- ✅ 4K-TV (HDMI) zeigt Login-Bildschirm
- ❌ Waveshare Display blinkt nur (grüne LED), zeigt kein Bild

## Ursache
HDMI wird als primäres Display verwendet, Waveshare Display wird nicht initialisiert.

## Lösung

### 1. SSH-Zugriff aktivieren (falls noch nicht aktiv)
- moOde Audio Web-Interface: System → SSH Server → Enable
- Oder direkt am Pi: SSH aktivieren

### 2. config.txt anpassen

**Wichtig:** In moOde Audio ist config.txt normalerweise in `/boot/config.txt`

```bash
# Mount boot partition read-write
sudo mount -o remount,rw /boot

# Backup erstellen
sudo cp /boot/config.txt /boot/config.txt.backup

# config.txt bearbeiten
sudo nano /boot/config.txt
```

**Hinzufügen/Anpassen:**

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

### 3. cmdline.txt prüfen

**Wichtig:** KEIN `video=` Parameter!

```bash
sudo nano /boot/cmdline.txt
```

Sollte sein:
```
root=PARTUUID=... rootwait ... console=tty1 ...
```

**NICHT:**
```
... video=DSI-1:1280x400@60 ...
```

### 4. Reboot

```bash
sudo reboot
```

## Nach Reboot prüfen

### 1. Display-Status
```bash
# I2C Bus 10 prüfen
sudo i2cdetect -y 10  # Sollte 0x45 zeigen

# Dependency Cycles prüfen
dmesg | grep -i "dependency cycle"

# DRM Devices
ls -la /sys/class/drm/
```

### 2. Framebuffer
```bash
ls -la /dev/fb*
cat /sys/class/graphics/fb0/virtual_size
```

### 3. Display-Auflösung
```bash
fbset
```

## Erwartetes Ergebnis

Nach Reboot:
- ✅ Waveshare Display zeigt moOde Audio Login
- ✅ 4K-TV zeigt nichts (HDMI deaktiviert)
- ✅ Grüne LED blinkt normal (nicht mehr dauerhaft)

## Falls Problem bleibt

1. Prüfe ob Overlay geladen ist:
   ```bash
   dmesg | grep -i waveshare
   ```

2. Prüfe Panel-Device:
   ```bash
   ls -la /proc/device-tree/soc/i2c0mux/i2c@1/panel_disp1@45/
   ```

3. Prüfe ws_touchscreen Problem:
   ```bash
   lsmod | grep ws_touchscreen
   dmesg | grep -i "ws_touchscreen"
   ```

