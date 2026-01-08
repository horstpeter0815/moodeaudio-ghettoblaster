# 🔍 Complete Shell Script Search Results

**Date:** 2025-12-19  
**Search:** Shell scripts in moOde repository that overwrite config.txt during boot

---

## 📊 Search Summary

**Total Shell Scripts Found:** 36 scripts in `moode-source/`

**Scripts That Reference config.txt or /boot/firmware:**
1. `moode-source/usr/local/bin/worker-php-patch.sh` - **PATCHES worker.php** (not the culprit)
2. `moode-source/usr/local/bin/first-boot-setup.sh` - References `/boot/firmware/overlays` and `/boot/firmware/ssh`
3. `moode-source/usr/local/bin/post-build-overlays.sh` - References `/boot/firmware/overlays`
4. `moode-source/usr/local/bin/force-ssh-on.sh` - References `/boot/firmware/ssh`

**NO SHELL SCRIPT FOUND that directly copies/overwrites config.txt!**

---

## 🔴 THE ACTUAL CULPRIT (Not a Shell Script)

**File:** `moode-source/www/daemon/worker.php` (PHP, not shell)  
**Function:** `chkBootConfigTxt()` in `moode-source/www/inc/common.php`

**The Problem:**
- `worker.php` calls `chkBootConfigTxt()` during startup
- If config.txt is missing headers, it runs:
  ```php
  sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');
  ```
- This **overwrites** the entire config.txt file

**Location in worker.php:**
- Line 106: `$status = chkBootConfigTxt();`
- Line 110: `sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');`
- Line 116: `sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');`

---

## ✅ THE FIX

**File:** `moode-source/usr/local/bin/worker-php-patch.sh`

**What it does:**
- Patches `worker.php` to restore `display_rotate=0` immediately after the copy
- Prevents endless loops by ensuring display_rotate is always set correctly

---

## 📋 All Shell Scripts Checked

### Custom Scripts (Our additions):
- ✅ `worker-php-patch.sh` - **FIXES the problem** (patches worker.php)
- ✅ `first-boot-setup.sh` - Sets up system, doesn't touch config.txt
- ✅ `auto-fix-display.sh` - Fixes display service, doesn't touch config.txt
- ✅ `xserver-ready.sh` - Checks X server, doesn't touch config.txt
- ✅ `i2c-monitor.sh` - Monitors I2C, doesn't touch config.txt
- ✅ `fix-network-ip.sh` - Fixes network, doesn't touch config.txt
- ✅ `post-build-overlays.sh` - Compiles overlays, doesn't touch config.txt
- ✅ `force-ssh-on.sh` - Enables SSH, doesn't touch config.txt

### moOde Original Scripts:
- ✅ `www/util/sysutil.sh` - System utilities, **NO config.txt references**
- ✅ `www/util/resizefs.sh` - Resize filesystem, **NO config.txt references**
- ✅ `www/util/system-updater.sh` - System updates, **NO config.txt references**
- ✅ `www/daemon/watchdog.sh` - Watchdog daemon, **NO config.txt references**
- ✅ All other moOde scripts - **NO config.txt overwriting found**

---

## 🎯 CONCLUSION

**There is NO shell script that overwrites config.txt!**

**The culprit is:**
- **PHP script:** `worker.php` 
- **Function:** `chkBootConfigTxt()` in `common.php`
- **Action:** Uses `sysCmd()` to run shell command `cp` to overwrite config.txt

**The fix:**
- **Shell script:** `worker-php-patch.sh` patches the PHP file to restore settings after overwrite

---

## 💡 Why It Seemed Like a Shell Script

The user remembered:
- "Shell script" - because `sysCmd()` runs shell commands
- "Overwrites everything" - because `cp` command overwrites the entire file
- "During boot" - because `worker.php` runs on boot
- "Arrow" - could be the flow: `worker.php → sysCmd() → cp command → overwrite`

**But it's actually PHP calling shell commands, not a standalone shell script!**

---

**Status:** ✅ **SEARCH COMPLETE - NO SHELL SCRIPT FOUND, IT'S PHP (worker.php)**

