# v1.0 Working Configuration - VERIFIED STABLE

**Date:** 2026-01-18  
**Status:** ✓ VERIFIED WORKING - DO NOT MODIFY  
**Boot Time:** 6.7 seconds  
**System:** Raspberry Pi 5, moOde Audio 10.0.3, HiFiBerry AMP100

## What This Is

This is the COMPLETE working configuration after boot optimization.
Everything here has been tested and verified to work perfectly.

## Performance

- Boot: 6.7 seconds (was 2+ minutes)
- Worker ready: <1 second (was 120+ seconds)
- UI load: 0.14 seconds (was 30+ seconds timeout)
- Audio: HiFiBerry AMP100 detected correctly, no retry loops
- Display: Correct orientation, touch working
- Network: No timeouts, immediate boot

## Key Settings (Database)

```sql
adevname = "HiFiBerry DAC+"
i2sdevice = "HiFiBerry DAC+"
cardnum = "1"
alsa_output_mode = "plughw"
ipaddr_timeout = "0"
camilladsp = "on"
```

## Disabled Services (systemd)

- NetworkManager-wait-online.service (masked)
- cloud-init* services (disabled)
- ModemManager.service (disabled)

## Files Included

1. `moode-sqlite3.sql` - Complete database dump
2. `cmdline.txt` - Boot command line with video parameter
3. `config.txt` - Boot configuration with HiFiBerry settings
4. `xinitrc` - X11 startup script (moOde default)
5. `disabled-services.txt` - List of disabled services
6. `boot-time.txt` - Boot time analysis

## How to Restore

```bash
# 1. Restore database (select settings only, don't restore entire DB)
ssh andre@192.168.2.3
sudo sqlite3 /var/local/www/db/moode-sqlite3.db "
UPDATE cfg_system SET value='HiFiBerry DAC+' WHERE param='adevname';
UPDATE cfg_system SET value='HiFiBerry DAC+' WHERE param='i2sdevice';
UPDATE cfg_system SET value='1' WHERE param='cardnum';
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
UPDATE cfg_system SET value='0' WHERE param='ipaddr_timeout';
"

# 2. Copy boot files
scp cmdline.txt andre@192.168.2.3:/tmp/
scp config.txt andre@192.168.2.3:/tmp/
ssh andre@192.168.2.3 "sudo cp /tmp/cmdline.txt /boot/firmware/ && sudo cp /tmp/config.txt /boot/firmware/"

# 3. Disable services
ssh andre@192.168.2.3
sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl mask NetworkManager-wait-online.service
sudo touch /etc/cloud/cloud-init.disabled
sudo systemctl disable cloud-init cloud-init-local cloud-final cloud-config
sudo systemctl disable ModemManager.service

# 4. Reboot
sudo reboot
```

## What Was Fixed

1. **Audio Device Detection** - Set correct device name in database
2. **Network Timeout** - Disabled 90-second wait
3. **Unnecessary Services** - Disabled cloud-init, ModemManager, NetworkManager-wait-online
4. **Display Orientation** - Correct cmdline.txt video parameter
5. **CamillaDSP Config** - Fixed symlink to bose_wave_filters.yml

## Documentation

See `/WISSENSBASIS/126_BOOT_OPTIMIZATION_ROOT_CAUSES.md` for complete analysis.
See `/WISSENSBASIS/127_BOOT_OPTIMIZATION_QUICK_REFERENCE.md` for quick commands.

## DO NOT BREAK THIS

This configuration is VERIFIED WORKING. If you need to make changes:
1. Create a NEW backup FIRST
2. Test changes thoroughly
3. Document what you changed
4. Always have a way to restore v1.0

**This is the baseline. Everything should be compared against this.**
