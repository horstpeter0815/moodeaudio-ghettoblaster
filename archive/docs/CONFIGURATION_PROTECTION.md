# Configuration Protection

## Protected Files

### 1. `/boot/firmware/config.txt`
**Critical settings:**
```ini
[pi5]
hdmi_timings=1280 32 48 80 400 10 3 2 60 35860 0 0 0 0 0
hdmi_group=2
hdmi_mode=87
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
display_rotate=0
```

**Backup:** `/boot/firmware/config.txt.working_backup`

### 2. `/boot/firmware/cmdline.txt`
**Critical setting:**
```
video=HDMI-A-2:1280x400M@60
```

**Backup:** `/boot/firmware/cmdline.txt.working_backup`

### 3. `/home/andre/.xinitrc`
**Contains:** Display mode setting and Chromium startup

**Backup:** `/home/andre/.xinitrc.working_backup`

## Restore Script

If configuration is overwritten by updates:

```bash
sudo /usr/local/bin/restore-display-config.sh
```

Then reboot.

## Documentation

See `/boot/firmware/DISPLAY_CONFIG_README.txt` for details.

## Touchscreen Configuration

**X11 Config:** `/etc/X11/xorg.conf.d/99-touchscreen.conf`

**USB ID:** `0712:000a` (WaveShare)

**Transformation Matrix:** `1 0 0 0 1 0 0 0 1` (no rotation for 1280x400 landscape)

## Protection Status
✅ Backups created
✅ Restore script created
✅ Documentation created
✅ Touchscreen configured

