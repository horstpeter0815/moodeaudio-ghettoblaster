# Waveshare Image Test Plan

## Nach dem Boot mit Waveshare Image:

### 1. SSH Zugang prüfen
- Hostname: ghettopi4.local (oder IP)
- User: pi (oder andre)
- Passwort: raspberry (oder 0815)

### 2. System Info
```bash
cat /etc/os-release
uname -a
```

### 3. Config.txt prüfen
```bash
cat /boot/firmware/config.txt | grep -v '^#' | grep -v '^$'
# oder
cat /boot/config.txt | grep -v '^#' | grep -v '^$'
```

### 4. Cmdline.txt prüfen
```bash
cat /boot/firmware/cmdline.txt
# oder
cat /boot/cmdline.txt
```

### 5. Display Status
```bash
xrandr | grep DSI
dmesg | grep -E 'dsi|panel|waveshare' | tail -20
```

### 6. I2C Status
```bash
i2cdetect -y 10
ls -la /sys/bus/i2c/devices/10-0045/driver
```

### 7. Panel Initialisierung
```bash
dmesg | grep -E 'panel.*probe|panel.*init|waveshare.*probe' | tail -10
cat /sys/class/drm/card0-DSI-*/status 2>/dev/null
```

