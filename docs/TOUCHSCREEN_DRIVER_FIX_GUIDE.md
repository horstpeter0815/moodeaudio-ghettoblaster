# Touchscreen Driver Initialization Fix Guide

## Problem Description

The Waveshare touchscreen driver (FT6236) initializes before the display panel, causing:
- I2C conflicts
- Unstable behavior on boot
- Touchscreen not working reliably
- Display initialization issues

## Root Cause

Device tree overlays and kernel modules are loaded in the wrong order:
1. FT6236 touchscreen driver loads first
2. Display panel initializes later
3. I2C bus conflicts occur
4. System becomes unstable

## Solution Approach

### 1. Check Current Load Order

```bash
# Check device tree overlays
cat /boot/firmware/config.txt | grep -i dtoverlay

# Check I2C devices
i2cdetect -y 1

# Check module load order
ls -la /etc/modules-load.d/
cat /etc/modules-load.d/*.conf

# Check systemd services
systemctl list-units | grep -i touch
systemctl list-units | grep -i display
systemctl list-units | grep -i i2c
```

### 2. Check Boot Logs

```bash
# Check for I2C errors
journalctl -b | grep -i "i2c\|ft6236\|touch"

# Check for display initialization
journalctl -b | grep -i "display\|drm\|vc4"

# Check module loading order
dmesg | grep -i "ft6236\|i2c\|touch"
```

### 3. Files to Modify

#### Device Tree Overlays
- Location: `/boot/firmware/config.txt`
- Check: `custom-components/configs/config.txt.template`
- Overlay files: `custom-components/overlays/`

#### Module Loading
- `/etc/modules-load.d/` - Module load order
- `/etc/modprobe.d/` - Module parameters

#### Systemd Services
- Check for touchscreen/display services
- Modify `After=` and `Before=` dependencies
- Add delays if needed

### 4. Potential Fixes

#### Option A: Device Tree Overlay Order
```bash
# In /boot/firmware/config.txt, ensure display overlay loads first:
dtoverlay=vc4-kms-v3d-pi5
dtoverlay=vc4-kms-dsi-waveshare-panel
# Then touchscreen:
dtoverlay=ft6236
```

#### Option B: Module Load Order
```bash
# Create /etc/modules-load.d/01-display.conf
vc4
drm
# Then /etc/modules-load.d/02-touchscreen.conf
ft6236
```

#### Option C: Systemd Service Dependencies
```ini
[Unit]
Description=Touchscreen Driver
After=display.service
Requires=display.service
```

#### Option D: Add Delay
```bash
# In systemd service or init script
sleep 2  # Wait for display to initialize
modprobe ft6236
```

### 5. I2C Stabilization Script

Check existing script:
- `custom-components/scripts/i2c-stabilize.sh`

This script may already handle some initialization order issues.

### 6. Testing

After making changes:
1. Reboot the Pi
2. Check boot logs: `journalctl -b | grep -i "i2c\|touch\|display"`
3. Test touchscreen: `evtest` or check `/dev/input/event*`
4. Verify I2C: `i2cdetect -y 1`

## Relevant Files in Project

```
custom-components/
├── overlays/
│   └── (device tree overlays)
├── scripts/
│   └── i2c-stabilize.sh  (I2C stabilization)
└── configs/
    └── config.txt.template

moode-source/
└── lib/systemd/system/
    └── (systemd services)

boot-config/
└── config.txt  (boot configuration)
```

## Useful Commands

```bash
# Check I2C bus
i2cdetect -y 1

# Check touchscreen device
ls -la /dev/input/event*
evtest  # Test touchscreen

# Check display
cat /sys/class/drm/card*/status

# Check module dependencies
modinfo ft6236
lsmod | grep ft6236

# Check device tree
ls /proc/device-tree/
find /proc/device-tree -name "*touch*" -o -name "*ft6236*"
```

## Next Steps

1. **Connect via WireGuard** (see CLIENT_WIREGUARD_SETUP.md)
2. **SSH into Pi:** `ssh andre@10.8.0.1`
3. **Investigate current state:**
   ```bash
   # Check boot logs
   journalctl -b | grep -i "i2c\|touch\|display" > /tmp/boot-analysis.txt
   
   # Check device tree
   cat /boot/firmware/config.txt | grep dtoverlay
   
   # Check I2C
   i2cdetect -y 1
   ```
4. **Identify exact load order issue**
5. **Implement fix** (device tree, modules, or systemd)
6. **Test and verify**

---

*Guide created: 2026-01-14*  
*For: andre.vollmer.mail@gmail.com*
