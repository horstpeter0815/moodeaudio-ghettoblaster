# 🔄 Complete Boot Process - Where Everything Gets Overwritten

**Date:** 2025-12-19  
**Problem:** All changes get "transcribed" (overwritten) during boot, username issues

---

## 🎯 THE COMPLETE BOOT PROCESS

### **Phase 1: Image Build (Before Boot)**

**During Build:**
1. **`imgbuild/pi-gen-64/stage1/00-boot-files/00-run.sh`**
   - Installs default `config.txt` to `/boot/firmware/`
   - This is the ORIGINAL config.txt that gets copied later

2. **`imgbuild/pi-gen-64/export-image/01-user-rename/01-run.sh`**
   - **CRITICAL FOR USERNAME:**
   ```bash
   if [[ "${DISABLE_FIRST_BOOT_USER_RENAME}" == "0" ]]; then
       rename-user -f -s  # This starts setup wizard!
   else
       rm -f "${ROOTFS_DIR}/etc/xdg/autostart/piwiz.desktop"  # Disable wizard
   fi
   ```
   - If `DISABLE_FIRST_BOOT_USER_RENAME=1` → Setup wizard disabled
   - If `DISABLE_FIRST_BOOT_USER_RENAME=0` → Setup wizard starts → **ENDLESS LOOP!**

3. **`imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh`**
   - Creates user "andre" during build
   - Applies worker.php patch
   - Sets up custom components

---

### **Phase 2: Boot Sequence (Runtime)**

**Timeline:**

```
00:00 - Kernel Boot
  └─> Reads /boot/firmware/config.txt (your custom version)

00:05 - Systemd Starts
  ├─> ssh-ultra-early.service
  │   └─> force-ssh-on.sh (enables SSH)
  │
  ├─> network-guaranteed.service
  │   └─> Ensures network ready
  │
  └─> first-boot-setup.service
      └─> first-boot-setup.sh
          ├─> Compile overlays
          ├─> Apply worker.php patch
          └─> Ensure user "andre" exists

00:30 - moOde Services Start
  └─> worker.php daemon starts
      │
      ├─> Check userid (getUserID())
      │   └─> If no user → ERROR (but continues)
      │
      ├─> Wait for Linux startup (up to 3 minutes)
      │
      └─> ⚠️ CRITICAL POINT: chkBootConfigTxt()
          │
          ├─> Reads /boot/firmware/config.txt
          ├─> Checks for required headers:
          │   - CFG_MAIN_FILE_HEADER
          │   - CFG_DEVICE_FILTERS_HEADER
          │   - CFG_GENERAL_SETTINGS_HEADER
          │   - CFG_DO_NOT_ALTER_HEADER
          │   - CFG_AUDIO_OVERLAYS_HEADER
          │
          └─> If headers missing:
              └─> sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/')
                  └─> ⚠️ OVERWRITES YOUR ENTIRE config.txt!
                      └─> All custom settings LOST!
```

---

## 🔴 THE OVERWRITE PROBLEM

### **What Gets Overwritten:**

1. **config.txt** - Completely replaced with default
   - Your `display_rotate=0` → GONE
   - Your custom HDMI settings → GONE
   - Your custom overlays → GONE
   - Everything → GONE

2. **Username** - Setup wizard starts
   - If `FIRST_USER_NAME` not set → wizard starts
   - Wizard asks for username → keyboard selection → back to start
   - **Endless loop!**

### **Why It Happens:**

**In worker.php (lines 105-118):**
```php
// CRITICAL: Check boot config.txt
$status = chkBootConfigTxt();
if ($status == 'Required headers present') {
    workerLog('worker: Boot config:   ok');
} else if ($status == 'Required header missing') {
    sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');
    // ⚠️ THIS OVERWRITES EVERYTHING!
    workerLog('worker: CRITICAL ERROR: Boot config is missing required headers');
    workerLog('worker: WARNING: Default boot config restored');
} else if ($status == 'Main header missing') {
    sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');
    sysCmd('reboot');
    // ⚠️ THIS ALSO OVERWRITES AND REBOOTS!
}
```

**The Problem:**
- `chkBootConfigTxt()` checks if config.txt has specific headers
- If ANY header is missing → assumes config.txt is corrupted
- **Solution:** Replace entire file with default
- **Result:** All your custom settings are lost

---

## 🔴 THE USERNAME PROBLEM

### **The Endless Loop:**

```
Boot → No FIRST_USER_NAME set
  └─> Setup wizard starts (piwiz.desktop)
      └─> Asks for username
          └─> Asks for keyboard layout
              └─> Goes back to username
                  └─> ENDLESS LOOP!
```

### **Why It Happens:**

**In `imgbuild/pi-gen-64/export-image/01-user-rename/01-run.sh`:**
```bash
if [[ "${DISABLE_FIRST_BOOT_USER_RENAME}" == "0" ]]; then
    rename-user -f -s  # Starts setup wizard
else
    rm -f "${ROOTFS_DIR}/etc/xdg/autostart/piwiz.desktop"  # Disables wizard
fi
```

**If `DISABLE_FIRST_BOOT_USER_RENAME=0` (default):**
- Setup wizard (`piwiz.desktop`) is enabled
- Wizard starts on first boot
- Asks for username → keyboard → back to start
- **Endless loop!**

**If `DISABLE_FIRST_BOOT_USER_RENAME=1` (our fix):**
- Setup wizard is disabled
- User "andre" already exists (created during build)
- No wizard → no loop → boot succeeds

---

## ✅ THE FIXES (Build 35)

### **1. Username Fix:**
**Build Configuration:**
```bash
FIRST_USER_NAME=andre
FIRST_USER_PASS=0815
DISABLE_FIRST_BOOT_USER_RENAME=1
```

**What it does:**
- Creates user "andre" during build
- Disables setup wizard (`piwiz.desktop`)
- Prevents endless loop

**Applied in:**
- `imgbuild/pi-gen-64/export-image/01-user-rename/01-run.sh`
- `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh`

### **2. config.txt Overwrite Fix:**
**Patch Script:** `worker-php-patch.sh`

**What it does:**
- Patches `worker.php` to restore `display_rotate=0` after overwrite
- Applied during build AND on first boot

**The Patch:**
```bash
sed -i '/sysCmd.*cp.*config.txt.*\/boot\/firmware\//a\
    // Ghettoblaster: Stelle display_rotate=0 wieder her (Landscape)\
    sysCmd("sed -i \"/^display_rotate=/d\" /boot/firmware/config.txt");\
    sysCmd("echo \"display_rotate=0\" >> /boot/firmware/config.txt");
' "$WORKER_FILE"
```

**Applied in:**
- `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh` (during build)
- `moode-source/usr/local/bin/first-boot-setup.sh` (on first boot)

---

## 📊 COMPLETE BOOT FLOW

```
┌─────────────────────────────────────────────────────────────┐
│ BOOT START                                                  │
└─────────────────────────────────────────────────────────────┘
         │
         ├─> Kernel: Read /boot/firmware/config.txt (custom)
         │
         ├─> Systemd: Start services
         │   │
         │   ├─> ssh-ultra-early.service
         │   │   └─> force-ssh-on.sh
         │   │
         │   ├─> network-guaranteed.service
         │   │
         │   └─> first-boot-setup.service
         │       └─> first-boot-setup.sh
         │           ├─> Create user "andre" (if missing)
         │           ├─> Compile overlays
         │           └─> Apply worker.php patch
         │
         └─> moOde: worker.php daemon starts
             │
             ├─> Check userid
             │   └─> If no user → ERROR (but continues)
             │
             ├─> Wait for Linux startup (up to 3 min)
             │
             └─> ⚠️ chkBootConfigTxt()
                 │
                 ├─> If headers OK → Continue ✅
                 │
                 └─> If headers MISSING → OVERWRITE! ❌
                     │
                     ├─> cp /usr/share/moode-player/.../config.txt /boot/firmware/
                     │   └─> ⚠️ YOUR CUSTOM config.txt REPLACED!
                     │
                     └─> worker.php patch restores display_rotate=0 ✅
                         └─> But other custom settings still lost!
```

---

## 🎯 THE "TRANSCRIBED" PROBLEM

**"Everything was transcribed" = Everything was overwritten/copied**

**What gets "transcribed" (overwritten):**

1. **config.txt** → Completely replaced with default
   - Source: `/usr/share/moode-player/boot/firmware/config.txt`
   - Destination: `/boot/firmware/config.txt`
   - Method: `cp` command (complete file copy)
   - Trigger: Missing headers in config.txt

2. **Username** → Setup wizard tries to create new user
   - If `FIRST_USER_NAME` not set → wizard starts
   - Wizard overwrites user creation process
   - Result: Endless loop

---

## 🔍 THE SHELL SCRIPT QUESTION

**You asked: "There is a shell script that overwrites everything"**

**Answer:**
- **NO standalone shell script** in repository overwrites config.txt
- **BUT:** `worker.php` (PHP) executes shell commands via `sysCmd()`
- The shell command is: `cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/`
- This is executed by PHP, not a standalone shell script

**The "arrow" (→) you remembered:**
- Flow: `worker.php → sysCmd() → cp command → overwrite config.txt`
- Or: `worker.php → chkBootConfigTxt() → copy default → overwrite`

---

## 📋 KEY FILES

1. **`worker.php`** - Overwrites config.txt (lines 110, 116)
2. **`chkBootConfigTxt()` in common.php** - Checks headers (line 559)
3. **`worker-php-patch.sh`** - Fixes overwrite (restores display_rotate)
4. **`first-boot-setup.sh`** - Creates user, applies patches
5. **`01-user-rename/01-run.sh`** - Controls setup wizard
6. **`/usr/share/moode-player/boot/firmware/config.txt`** - Default config (source)

---

**Status:** ✅ **COMPLETE BOOT PROCESS ANALYZED - ALL OVERWRITE POINTS IDENTIFIED**

**The problem:** worker.php overwrites config.txt, username setup causes endless loop
**The fixes:** worker-php-patch.sh + FIRST_USER_NAME configuration

