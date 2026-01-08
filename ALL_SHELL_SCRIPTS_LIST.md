# 📋 Complete List of All Shell Scripts in moOde Repository

**Date:** 2025-12-19  
**Total:** 36 shell scripts found

---

## Complete List

1. `moode-source/home/piano.sh`
2. `moode-source/usr/local/bin/i2c-stabilize.sh`
3. `moode-source/usr/local/bin/auto-fix-display.sh`
4. `moode-source/usr/local/bin/xserver-ready.sh`
5. `moode-source/usr/local/bin/i2c-monitor.sh`
6. `moode-source/usr/local/bin/worker-php-patch.sh`
7. `moode-source/usr/local/bin/audio-optimize.sh`
8. `moode-source/usr/local/bin/peppymeter-wrapper.sh`
9. `moode-source/usr/local/bin/start-chromium-clean.sh`
10. `moode-source/usr/local/bin/first-boot-setup.sh`
11. `moode-source/usr/local/bin/pcm5122-oversampling.sh`
12. `moode-source/usr/local/bin/fix-network-ip.sh`
13. `moode-source/usr/local/bin/post-build-overlays.sh`
14. `moode-source/usr/local/bin/force-ssh-on.sh`
15. `moode-source/var/local/www/commandw/restart.sh`
16. `moode-source/var/local/www/commandw/spspre.sh`
17. `moode-source/var/local/www/commandw/slpower.sh`
18. `moode-source/var/local/www/commandw/spotevent.sh`
19. `moode-source/var/local/www/commandw/deezevent.sh`
20. `moode-source/var/local/www/commandw/spspost.sh`
21. `moode-source/var/local/www/commandw/ready-script.sh`
22. `moode-source/www/util/sysinfo.sh`
23. `moode-source/www/util/vol.sh`
24. `moode-source/www/util/blu-control.sh`
25. `moode-source/www/util/automount.sh`
26. `moode-source/www/util/gen-cert.sh`
27. `moode-source/www/util/list-songfiles.sh`
28. `moode-source/www/util/chromium-updater.sh`
29. `moode-source/www/util/sysutil.sh`
30. `moode-source/www/util/resizefs.sh`
31. `moode-source/www/util/system-updater.sh`
32. `moode-source/www/util/rotvol.sh`
33. `moode-source/www/util/plugin-updater.sh`
34. `moode-source/www/daemon/aplmeta-reader.sh`
35. `moode-source/www/daemon/watchdog.sh`
36. `moode-source/www/daemon/lcd-updater.sh`

---

## Scripts That Reference config.txt or /boot/firmware

### Direct References:
1. **worker-php-patch.sh** - Patches worker.php (not overwriting config.txt itself)
2. **first-boot-setup.sh** - References `/boot/firmware/overlays` and `/boot/firmware/ssh`
3. **post-build-overlays.sh** - References `/boot/firmware/overlays`
4. **force-ssh-on.sh** - References `/boot/firmware/ssh`

### No Direct config.txt Overwriting Found in Any Shell Script

---

## Detailed Analysis Needed

Checking each script for:
- `cp` commands
- `config.txt` references
- `/boot/firmware/` references
- `overwrite` operations
- `sysCmd` calls

---

**Status:** 🔍 **ANALYZING ALL 36 SCRIPTS IN DETAIL**

