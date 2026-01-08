# 🔴 CRITICAL FINDING: worker.php Overwrites config.txt

**Date:** 2025-12-19  
**Build:** ~50+ (discovered around build 50)  
**Problem:** Endless loops caused by worker.php overwriting config.txt on every boot

---

## ❌ THE PROBLEM

**File:** `moode-source/www/daemon/worker.php`  
**Issue:** This PHP script contains a line that **copies/overwrites config.txt** on every boot, undoing all custom configuration changes.

**Result:** 
- Custom display settings get overwritten
- Endless loops (config changed → worker.php overwrites → config changed → ...)
- All manual fixes get lost on reboot

---

## 🔍 THE CULPRIT

**In worker.php, there's a line like:**
```php
sysCmd("cp ... config.txt ... /boot/firmware/");
```

This command **overwrites** the config.txt file, removing all custom settings including:
- `display_rotate=0` (or `display_rotate=3`)
- Custom HDMI settings
- Other custom configurations

---

## ✅ THE SOLUTION (worker-php-patch.sh)

**File:** `moode-source/usr/local/bin/worker-php-patch.sh`

**What it does:**
1. Finds the line in worker.php that copies config.txt
2. **Patches it** to restore `display_rotate=0` immediately after the copy
3. Prevents the endless loop by ensuring display_rotate is always set correctly

**The patch:**
```bash
sed -i '/sysCmd.*cp.*config.txt.*\/boot\/firmware\//a\
		// Ghettoblaster: Stelle display_rotate=0 wieder her (Landscape)\
		sysCmd("sed -i \"/^display_rotate=/d\" /boot/firmware/config.txt");\
		sysCmd("echo \"display_rotate=0\" >> /boot/firmware/config.txt");
' "$WORKER_FILE"
```

**Translation:**
- After worker.php copies config.txt
- Delete any existing `display_rotate=` line
- Add `display_rotate=0` back

---

## 📋 WHERE IT'S APPLIED

1. **During Build:** `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh`
2. **On First Boot:** `moode-source/usr/local/bin/first-boot-setup.sh`
3. **Manual:** Can be run manually if needed

---

## 🎯 KEY INSIGHT

**The "arrow" (→) you remembered:**
- Could be the flow: `worker.php → copies config.txt → overwrites settings → endless loop`
- Or the patch flow: `worker.php → patch → restores display_rotate=0`

**"Everything was transcribed":**
- worker.php was **copying/overwriting** (transcribing) the config.txt file
- All your changes were being **lost/overwritten** on every boot

---

## ⚠️ IMPORTANT

This patch is **CRITICAL** for Build 35 and all future builds. Without it:
- Display rotation will be wrong
- Endless loops will occur
- Custom settings will be lost on reboot

**Status:** ✅ **PATCH INTEGRATED IN BUILD 35**

---

## 📝 FILES INVOLVED

- `moode-source/www/daemon/worker.php` - The culprit (overwrites config.txt)
- `moode-source/usr/local/bin/worker-php-patch.sh` - The fix (patches worker.php)
- `moode-source/usr/local/bin/first-boot-setup.sh` - Applies patch on first boot
- `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh` - Applies patch during build

---

**This was the critical finding around build 50 that caused endless loops!**

