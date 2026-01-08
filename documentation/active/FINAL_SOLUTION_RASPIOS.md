# Final Solution: 1280x400 on RaspiOS Full

## Working Configuration

### config.txt
```ini
[pi5]
hdmi_timings=1280 32 48 80 400 10 3 2 60 35860 0 0 0 0 0
hdmi_group=2
hdmi_mode=87
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
display_rotate=0
```

**CRITICAL:** `disable_fw_kms_setup=1` must be **REMOVED** (not present in config.txt).

### Why This Works
1. **Without `disable_fw_kms_setup`**, firmware can inject custom modes into KMS
2. **`hdmi_timings`** is recognized by firmware: `hdmi_timings:0=1280 32 48 80 400 10 3 2 60 35860 0 0 0 0 0`
3. **KMS shows `1280x400` in available modes**: `cat /sys/class/drm/card1-HDMI-A-2/modes`

### Setting the Mode

#### Option 1: Via xrandr (when X11 is running)
```bash
export DISPLAY=:0
xrandr --output HDMI-A-2 --mode 1280x400
```

#### Option 2: Via systemd service (before X11)
Create `/etc/systemd/system/set-display-1280x400.service`:
```ini
[Unit]
Description=Set Display Mode to 1280x400
After=graphical.target
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 2 && if grep -q "1280x400" /sys/class/drm/card1-HDMI-A-2/modes; then echo "1280x400" > /sys/class/drm/card1-HDMI-A-2/mode 2>/dev/null || true; fi'
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
```

#### Option 3: Via xinitrc (when X11 starts)
Add to `~/.xinitrc`:
```bash
sleep 2
export DISPLAY=:0
if xrandr 2>/dev/null | grep -q "1280x400"; then
    xrandr --output HDMI-A-2 --mode 1280x400 2>/dev/null
fi
```

## Verification
```bash
# Check available modes
cat /sys/class/drm/card1-HDMI-A-2/modes

# Check current resolution (X11)
DISPLAY=:0 xrandr | grep "current"

# Check firmware config
vcgencmd get_config hdmi_timings
```

## Next: Apply to Moode Audio
1. Remove `disable_fw_kms_setup=1` from `/boot/config.txt`
2. Add `hdmi_timings` to `[pi5]` section
3. Set mode via xrandr in Moode's display startup script
4. Test touchscreen calibration

