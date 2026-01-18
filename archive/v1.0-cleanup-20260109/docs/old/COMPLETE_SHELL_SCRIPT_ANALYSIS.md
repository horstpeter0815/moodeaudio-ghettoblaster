# 🔍 Complete Shell Script Analysis - All 36 Scripts

**Date:** 2025-12-19  
**Total Scripts:** 36 shell scripts in `moode-source/`

---

## 📋 Complete List with Analysis

### Custom Scripts (Our additions - 14 scripts):

1. **`moode-source/usr/local/bin/worker-php-patch.sh`** ✅
   - **Purpose:** Patches worker.php to restore display_rotate=0
   - **References config.txt:** YES (but only to restore it, not overwrite)
   - **Boot execution:** Via first-boot-setup.sh

2. **`moode-source/usr/local/bin/first-boot-setup.sh`** ✅
   - **Purpose:** Runs on first boot, compiles overlays, applies patches
   - **References config.txt:** NO (only references /boot/firmware/overlays and /boot/firmware/ssh)
   - **Boot execution:** Yes (first-boot-setup.service)

3. **`moode-source/usr/local/bin/auto-fix-display.sh`** ✅
   - **Purpose:** Auto-fixes display service
   - **References config.txt:** NO
   - **Boot execution:** Yes (auto-fix-display.service)

4. **`moode-source/usr/local/bin/xserver-ready.sh`** ✅
   - **Purpose:** Checks if X Server is ready
   - **References config.txt:** NO
   - **Boot execution:** Yes (xserver-ready.service, localdisplay.service)

5. **`moode-source/usr/local/bin/i2c-monitor.sh`** ✅
   - **Purpose:** Monitors I2C bus
   - **References config.txt:** NO
   - **Boot execution:** Yes (i2c-monitor.service)

6. **`moode-source/usr/local/bin/i2c-stabilize.sh`** ✅
   - **Purpose:** Stabilizes I2C
   - **References config.txt:** NO
   - **Boot execution:** Yes (i2c-stabilize.service)

7. **`moode-source/usr/local/bin/audio-optimize.sh`** ✅
   - **Purpose:** Optimizes ALSA configuration
   - **References config.txt:** NO (only backs up ALSA config)
   - **Boot execution:** Yes (audio-optimize.service)

8. **`moode-source/usr/local/bin/peppymeter-wrapper.sh`** ✅
   - **Purpose:** Wraps PeppyMeter
   - **References config.txt:** NO
   - **Boot execution:** Yes (peppymeter.service)

9. **`moode-source/usr/local/bin/start-chromium-clean.sh`** ✅
   - **Purpose:** Starts Chromium cleanly
   - **References config.txt:** NO
   - **Boot execution:** Yes (localdisplay.service)

10. **`moode-source/usr/local/bin/pcm5122-oversampling.sh`** ✅
    - **Purpose:** PCM5122 oversampling
    - **References config.txt:** NO
    - **Boot execution:** No

11. **`moode-source/usr/local/bin/fix-network-ip.sh`** ✅
    - **Purpose:** Fixes network IP configuration
    - **References config.txt:** NO (only network configs)
    - **Boot execution:** Yes (fix-network-ip.service)

12. **`moode-source/usr/local/bin/post-build-overlays.sh`** ✅
    - **Purpose:** Compiles overlays after build
    - **References config.txt:** NO (only /boot/firmware/overlays)
    - **Boot execution:** No (build-time only)

13. **`moode-source/usr/local/bin/force-ssh-on.sh`** ✅
    - **Purpose:** Forces SSH to be enabled
    - **References config.txt:** NO (only /boot/firmware/ssh)
    - **Boot execution:** Yes (ssh-ultra-early.service)

14. **`moode-source/home/piano.sh`** ✅
    - **Purpose:** Piano DAC control
    - **References config.txt:** NO
    - **Boot execution:** No

### moOde Original Scripts (22 scripts):

15. **`moode-source/www/util/sysutil.sh`** ✅
    - **Purpose:** System utilities
    - **References config.txt:** NO
    - **Boot execution:** No (called on demand)

16. **`moode-source/www/util/vol.sh`** ✅
    - **Purpose:** Volume control
    - **References config.txt:** NO
    - **Boot execution:** No

17. **`moode-source/www/util/blu-control.sh`** ✅
    - **Purpose:** Bluetooth control
    - **References config.txt:** NO
    - **Boot execution:** No

18. **`moode-source/www/util/automount.sh`** ✅
    - **Purpose:** Auto-mount
    - **References config.txt:** NO
    - **Boot execution:** No

19. **`moode-source/www/util/gen-cert.sh`** ✅
    - **Purpose:** Generate certificates
    - **References config.txt:** NO
    - **Boot execution:** No

20. **`moode-source/www/util/list-songfiles.sh`** ✅
    - **Purpose:** List song files
    - **References config.txt:** NO
    - **Boot execution:** No

21. **`moode-source/www/util/chromium-updater.sh`** ✅
    - **Purpose:** Update Chromium
    - **References config.txt:** NO
    - **Boot execution:** No

22. **`moode-source/www/util/sysinfo.sh`** ✅
    - **Purpose:** System information
    - **References config.txt:** NO
    - **Boot execution:** No

23. **`moode-source/www/util/resizefs.sh`** ✅
    - **Purpose:** Resize filesystem
    - **References config.txt:** NO
    - **Boot execution:** No (one-time)

24. **`moode-source/www/util/system-updater.sh`** ⚠️ **IMPORTANT**
    - **Purpose:** System updater - downloads and installs updates
    - **References config.txt:** NO directly, BUT calls `update$MOODE_SERIES/install.sh`
    - **Boot execution:** No (called by worker.php when update available)
    - **Note:** This script calls `update$MOODE_SERIES/install.sh` which might contain config.txt operations!

25. **`moode-source/www/util/rotvol.sh`** ✅
    - **Purpose:** Rotary volume
    - **References config.txt:** NO
    - **Boot execution:** No

26. **`moode-source/www/util/plugin-updater.sh`** ✅
    - **Purpose:** Plugin updater
    - **References config.txt:** NO
    - **Boot execution:** No

27. **`moode-source/www/daemon/aplmeta-reader.sh`** ✅
    - **Purpose:** APL metadata reader
    - **References config.txt:** NO
    - **Boot execution:** No

28. **`moode-source/www/daemon/watchdog.sh`** ✅
    - **Purpose:** Watchdog daemon
    - **References config.txt:** NO
    - **Boot execution:** Yes (watchdog service)

29. **`moode-source/www/daemon/lcd-updater.sh`** ✅
    - **Purpose:** LCD updater
    - **References config.txt:** NO
    - **Boot execution:** No

30. **`moode-source/var/local/www/commandw/restart.sh`** ✅
    - **Purpose:** Restart commands
    - **References config.txt:** NO
    - **Boot execution:** No

31. **`moode-source/var/local/www/commandw/spspre.sh`** ✅
    - **Purpose:** Spotify pre-event
    - **References config.txt:** NO
    - **Boot execution:** No

32. **`moode-source/var/local/www/commandw/slpower.sh`** ✅
    - **Purpose:** Squeezelite power
    - **References config.txt:** NO
    - **Boot execution:** No

33. **`moode-source/var/local/www/commandw/spotevent.sh`** ✅
    - **Purpose:** Spotify event
    - **References config.txt:** NO
    - **Boot execution:** No

34. **`moode-source/var/local/www/commandw/deezevent.sh`** ✅
    - **Purpose:** Deezer event
    - **References config.txt:** NO
    - **Boot execution:** No

35. **`moode-source/var/local/www/commandw/spspost.sh`** ✅
    - **Purpose:** Spotify post-event
    - **References config.txt:** NO
    - **Boot execution:** No

36. **`moode-source/var/local/www/commandw/ready-script.sh`** ✅
    - **Purpose:** Ready script (plays chime)
    - **References config.txt:** NO
    - **Boot execution:** No (called by worker.php after startup)

---

## 🔍 Key Finding: system-updater.sh

**File:** `moode-source/www/util/system-updater.sh`

**Line 51:** `update$MOODE_SERIES/install.sh`

**This script downloads updates and calls `install.sh` from the update package!**

**The `install.sh` in update packages might be the culprit!**

---

## ❓ Missing Scripts to Check

The update packages contain `install.sh` scripts that are NOT in the moode-source repository - they come from update packages!

**These install.sh scripts might:**
- Copy config.txt from `/usr/share/moode-player/boot/firmware/config.txt`
- Overwrite config.txt during updates
- Run during boot after updates

---

## 🎯 Conclusion

**NO shell script in the moode-source repository directly overwrites config.txt!**

**BUT:**
- `system-updater.sh` calls `update$MOODE_SERIES/install.sh` from update packages
- These `install.sh` scripts are NOT in the repository
- They might be the culprit that overwrites config.txt

**The actual problem:**
- `worker.php` (PHP) calls `chkBootConfigTxt()` which overwrites config.txt
- Update `install.sh` scripts (if they exist) might also overwrite config.txt
- These install.sh scripts are downloaded from update packages, not in source

---

**Status:** ✅ **ALL 36 SCRIPTS ANALYZED - NO DIRECT config.txt OVERWRITE FOUND IN SOURCE**

**Next:** Check if update install.sh scripts exist or were used around build 50

