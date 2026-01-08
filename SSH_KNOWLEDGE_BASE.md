# SSH Access Knowledge Base - Complete Analysis

## Executive Summary

**Problem:** SSH access to moOde Audio is unreliable and keeps getting disabled.

**Root Cause:** Standard moOde downloads have SSH disabled by default with no persistent mechanism to keep it enabled.

**Solution Status:** Multiple approaches attempted, but none fully tested and verified.

---

## 1. How SSH Works in moOde

### Standard moOde Behavior

**Standard moOde downloads:**
- SSH is **disabled by default**
- No automatic SSH enabling mechanism
- No first-boot setup script
- No user creation mechanism
- Only default users: "moode" or "pi" (if set via Pi Imager)

**How SSH gets enabled:**
1. **Boot flag method**: Create `/boot/ssh` or `/boot/firmware/ssh` file before first boot
2. **Raspberry Pi OS** reads this flag and enables SSH on first boot
3. **After first boot**, the flag may be removed by the system
4. **No persistence** - SSH can be disabled by moOde processes

### Custom Build Behavior

**Custom builds** (like in this project) can include:
- `first-boot-setup.service` - Runs once on first boot
- `ssh-guaranteed.service` - Ensures SSH stays enabled
- `ssh-watchdog.service` - Continuously monitors and restarts SSH
- Custom scripts in `rc.local` or systemd services

**Files involved:**
- `moode-source/lib/systemd/system/ssh-guaranteed.service` - Multi-layer SSH activation
- `moode-source/lib/systemd/system/ssh-watchdog.service` - Continuous monitoring
- `moode-source/usr/local/bin/first-boot-setup.sh` - First boot user/SSH setup
- `moode-source/usr/local/bin/force-ssh-on.sh` - Aggressive SSH enabling script

---

## 2. First Boot Process

### Standard moOde

**Standard moOde has NO first-boot setup script.**

Boot sequence:
1. Raspberry Pi OS boots
2. Reads `/boot/ssh` flag (if present) → enables SSH
3. moOde's `worker.php` daemon starts
4. `worker.php` checks for user ID (UID 1000:1000)
5. System is ready

**No automatic:**
- User creation
- SSH enabling (beyond boot flag)
- Custom configuration

### Custom Build First Boot

**Custom builds** can include `first-boot-setup.service`:

**Service file:** `moode-source/lib/systemd/system/first-boot-setup.service`
- Runs after `network.target` and `local-fs.target`
- Before `localdisplay.service` and `auto-fix-display.service`
- Type: oneshot (runs once)
- Creates marker file `/var/lib/first-boot-setup.done` to prevent re-running

**Script:** `moode-source/usr/local/bin/first-boot-setup.sh`

**What it does:**
1. Checks marker file (runs only once)
2. Compiles custom device tree overlays
3. Applies patches (e.g., worker.php)
4. Creates utility scripts
5. **Creates user "andre"** (UID 1000, GID 1000)
6. **Enables SSH** (multiple methods)
7. Sets up services
8. Creates marker file to prevent re-running

**Key point:** This script only runs **once** on first boot. If it fails or doesn't run, the user won't be created.

---

## 3. User Creation and Attachment

### How moOde Identifies Users

**Function:** `getUserID()` in `moode-source/www/inc/common.php`

**Process:**
1. Checks for user with **UID 1000:1000** in `/etc/passwd`
2. Extracts username from that entry
3. Uses that username for moOde operations

**Code:**
```php
function getUserID() {
    // Check for userid with UID 1000:1000
    $userId = sysCmd('grep 1000:1000 /etc/passwd | cut -d: -f1')[0];
    // Returns username or NO_USERID_DEFINED
}
```

**Critical requirement:** moOde **requires** a user with UID 1000:1000 to function properly.

### Standard moOde User Setup

**Standard moOde:**
- Expects user to be created **before** moOde runs
- Typically uses "pi" or "moode" user (UID 1000)
- User must be created via:
  - Pi Imager (sets userid during image write)
  - Manual creation before boot
  - Physical console access

**Pi Imager method:**
- When writing image, Pi Imager can set userid
- Creates user with UID 1000
- Sets password
- Unlocks account (removes `!` from `/etc/shadow`)

**If no userid set:**
- `/etc/shadow` shows `pi:!` (locked)
- `getUserID()` returns `NO_USERID_DEFINED`
- moOde logs: "CRITICAL ERROR: Userid does not exist, moOde will not function"

### Custom Build User Creation

**Custom builds** can create user automatically:

**In `first-boot-setup.sh`:**
```bash
# Create user "andre" if doesn't exist
if ! id -u andre &>/dev/null; then
    useradd -m -s /bin/bash -u 1000 -g 1000 andre
    echo "andre:0815" | chpasswd
    # Add to groups
    usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre
fi
```

**Requirements:**
- Must run **before** moOde worker.php starts
- Must create user with **UID 1000:1000**
- Must set password
- Must unlock account (password set, not `!` in shadow)

---

## 4. SSH Installation Scripts Analysis

### Script 1: ENABLE_SSH_MOODE_STANDARD.sh

**Complexity:** ⭐ Simple  
**Reliability:** ⭐⭐ Basic  
**Features:** ⭐ Minimal

**What it does:**
- Creates `/boot/firmware/ssh` or `/boot/ssh` flag file
- Applies config.txt file
- No systemd services
- No watchdog
- No rc.local fallback

**Strengths:**
✅ Simple and straightforward  
✅ Good SD card detection  
✅ Handles both Pi 4 and Pi 5  
✅ Applies config.txt automatically  

**Weaknesses:**
❌ Only creates flag file - relies entirely on Raspberry Pi OS  
❌ No systemd service - SSH can be disabled by moOde  
❌ No watchdog - no continuous monitoring  
❌ No rc.local fallback  
❌ No verification after installation  

**Status:** ⚠️ **NOT RELIABLE** - SSH can be disabled after boot

---

### Script 2: INSTALL_INDEPENDENT_SSH.sh

**Complexity:** ⭐⭐ Medium  
**Reliability:** ⭐⭐⭐ Good  
**Features:** ⭐⭐ Moderate

**What it does:**
- Creates SSH flag file
- Creates `/boot/firmware/ssh-activate.sh` activation script
- Creates `independent-ssh.service` systemd service
- Creates `/etc/rc.local` fallback
- No watchdog service

**Strengths:**
✅ Creates activation script that can be reused  
✅ Systemd service with multiple targets  
✅ rc.local fallback for early boot  
✅ Handles rootfs mounting gracefully  

**Weaknesses:**
❌ Basic SD card detection  
❌ No watchdog service  
❌ No verification step  
❌ Limited error handling  

**Status:** ⚠️ **PARTIALLY RELIABLE** - Better than script 1, but no continuous monitoring

---

### Script 3: install-ssh-guaranteed-on-sd.sh

**Complexity:** ⭐⭐⭐ Comprehensive  
**Reliability:** ⭐⭐⭐⭐ Very Good  
**Features:** ⭐⭐⭐⭐ Extensive

**What it does:**
- Creates SSH flag file (both locations)
- Creates `ssh-guaranteed.service` systemd service (inline script)
- Creates `ssh-watchdog.service` for continuous monitoring
- Creates `/etc/rc.local` fallback
- Includes verification step

**Strengths:**
✅ **Watchdog service** - continuously monitors and restarts SSH  
✅ Good SD card detection  
✅ Verification step after installation  
✅ Multiple layers: flag, service, watchdog, rc.local  
✅ Handles rootfs availability gracefully  

**Weaknesses:**
❌ Watchdog waits for `network-online.target` - may start too late  
❌ Inline script in service (harder to modify)  
❌ No separate activation script for reuse  

**Status:** ✅ **MOST RELIABLE** - Has watchdog for continuous monitoring

---

### Script 4: install-independent-ssh-sd-card.sh

**Complexity:** ⭐⭐⭐⭐ Most Robust  
**Reliability:** ⭐⭐⭐⭐⭐ Excellent  
**Features:** ⭐⭐⭐⭐ Extensive

**What it does:**
- Creates SSH flag file with robust error handling
- Creates `/boot/firmware/ssh-activate.sh` activation script
- Creates `independent-ssh.service` systemd service
- Creates `/etc/rc.local` fallback
- Includes comprehensive verification
- No watchdog service

**Strengths:**
✅ **Best error handling** - multiple methods for SSH flag creation  
✅ **Comprehensive verification** - checks all files after installation  
✅ Separate activation script (reusable, readable)  
✅ Systemd service with multiple targets  
✅ Handles directory vs file conflicts for SSH flag  
✅ Good SD card detection  
✅ Multiple ExecStartPost calls for redundancy  

**Weaknesses:**
❌ No watchdog service - no continuous monitoring after boot  

**Status:** ✅ **EXCELLENT** - Best error handling and verification, but lacks watchdog

---

## 5. Systemd Services Analysis

### ssh-asap.service

**Purpose:** Start SSH as early as possible

**Timing:**
- `After=local-fs.target`
- `Before=sysinit.target`
- `Before=basic.target`
- `Before=network.target`
- `Before=cloud-init.target`
- `Before=moode-startup.service`

**What it does:**
- Creates SSH flag files
- Enables SSH service
- Starts SSH service
- Tries to start sshd directly if systemctl not ready
- Runs multiple times for safety

**Status:** ✅ **EARLIEST START** - Runs before everything else

---

### ssh-guaranteed.service

**Purpose:** Multiple safety layers to guarantee SSH

**Timing:**
- `After=local-fs.target`
- `Before=network.target`
- `Before=cloud-init.target`
- `Before=moode-startup.service`
- `Before=sysinit.target`

**What it does:**
- Layer 1: SSH flag file
- Layer 2: Enable SSH service
- Layer 3: Unmask SSH
- Layer 4: Start SSH
- Layer 5: Create symlinks
- Layer 6: Ensure SSH keys exist
- Layer 7: SSH config (Port 22)
- Layer 8: Permissions
- Layer 9: Firewall rules
- Runs every 30 seconds for first 5 minutes

**Status:** ✅ **MULTIPLE LAYERS** - Very comprehensive

---

### ssh-watchdog.service

**Purpose:** Continuously monitor and restart SSH if it stops

**Timing:**
- `After=local-fs.target`
- `Before=network.target`
- `Before=cloud-init.target`
- **Problem:** Original version had `After=network-online.target` - TOO LATE!

**What it does:**
- Checks if SSH is running every 30 seconds
- Restarts SSH if not running
- Ensures SSH flag exists
- Continuous loop

**Status:** ✅ **CONTINUOUS MONITORING** - But timing must be correct

---

### ssh-ultra-early.service

**Purpose:** Ultra early SSH activation

**Timing:**
- `After=local-fs.target`
- `Before=sysinit.target`
- `Before=basic.target`
- `Before=network.target`
- `Before=moode-startup.service`

**What it does:**
- Calls `force-ssh-on.sh` script
- Runs multiple times for safety

**Status:** ✅ **VERY EARLY** - Uses force-ssh-on.sh script

---

### force-ssh-on.sh

**Purpose:** Aggressive SSH enabling script

**What it does:**
- Method 1: Flag files
- Method 2: systemctl enable
- Method 3: Manual symlinks
- Method 4: Unmask
- Method 5: Start
- Method 6: Restart every 10 seconds for first minute
- Method 7: Generate SSH keys
- Method 8: SSH config
- Method 9: Port 22
- Method 10: Firewall rules
- Method 11: Permissions

**Status:** ✅ **MOST AGGRESSIVE** - 11 different methods

---

## 6. Boot Sequence Analysis

### Standard moOde Boot

```
1. Raspberry Pi OS boots
   ↓
2. Reads /boot/ssh flag → enables SSH (if present)
   ↓
3. Systemd services start
   ↓
4. moOde worker.php daemon starts
   ↓
5. worker.php calls getUserID()
   ↓
6. If UID 1000:1000 user exists → moOde works
   If not → CRITICAL ERROR logged
   ↓
7. moOde Web UI available
```

### Custom Build Boot (with first-boot-setup)

```
1. Raspberry Pi OS boots
   ↓
2. Reads /boot/ssh flag → enables SSH (if present)
   ↓
3. Systemd services start
   ↓
4. ssh-asap.service runs (EARLIEST)
   ↓
5. ssh-guaranteed.service runs (MULTIPLE LAYERS)
   ↓
6. ssh-watchdog.service runs (CONTINUOUS MONITORING)
   ↓
7. first-boot-setup.service runs (if marker doesn't exist)
   ↓
8. first-boot-setup.sh executes:
   - Creates user "andre" (UID 1000:1000)
   - Enables SSH
   - Sets up services
   - Creates marker file
   ↓
9. moOde worker.php daemon starts
   ↓
10. worker.php calls getUserID()
   ↓
11. Finds user "andre" (UID 1000:1000) → moOde works
   ↓
12. moOde Web UI available
```

---

## 7. Why SSH Keeps Getting Disabled

### Possible Causes

1. **moOde worker.php** might disable SSH
   - No evidence in code, but possible
   - Security hardening might disable it

2. **System updates** reset SSH state
   - Updates might disable SSH
   - Config files get overwritten

3. **Boot flag removed**
   - `/boot/ssh` flag gets deleted after first use
   - No mechanism to recreate it

4. **Service conflicts**
   - Multiple SSH services (ssh vs sshd)
   - Service masking/unmasking issues

5. **Standard moOde has no persistence**
   - No watchdog service
   - No guarantee SSH stays enabled

6. **Timing issues**
   - Services start too late
   - moOde disables SSH before services can enable it

---

## 8. What Actually Works

### For Standard moOde (SD Card Installation)

**Method 1: Boot flag + systemd service** ✅
- Create `/boot/ssh` before boot
- Create systemd service that enables SSH on every boot
- Service must run early (before moOde starts)

**Method 2: rc.local fallback** ✅
- Add SSH enabling to `/etc/rc.local`
- Runs after systemd but before user login
- Less reliable than systemd

**Method 3: SSH watchdog** ✅✅✅
- Continuous monitoring service
- Restarts SSH if it stops
- Most reliable but resource-intensive

**Method 4: Multiple layers** ✅✅✅✅
- Boot flag + systemd service + watchdog + rc.local
- Maximum reliability

### For Custom Builds

**Include in build:**
1. `first-boot-setup.service` - Creates user and enables SSH once
2. `ssh-guaranteed.service` - Multi-layer SSH activation on every boot
3. `ssh-watchdog.service` - Continuous monitoring
4. `rc.local` entry - Fallback safety layer

**All layers together ensure SSH stays enabled.**

---

## 9. Current SD Card Status

**Last known state:**
- Boot partition: `/Volumes/bootfs` (if mounted)
- Rootfs partition: `/Volumes/rootfs` (if mounted via ExtFS)

**Files created:**
- `/boot/firmware/create-user-on-boot.sh` - User creation script
- `/boot/firmware/ssh-activate.sh` - SSH activation script (updated to call user creation)
- `/boot/ssh` - SSH enable flag
- `/boot/create-user-on-boot.sh` - Backup copy

**rc.local:**
- Calls `/boot/firmware/ssh-activate.sh`
- Should call user creation script

**Status:** ⚠️ **NOT VERIFIED** - Files were created but not tested after boot

---

## 10. Recommended Solution

### For Standard moOde (Current Situation)

**Use:** `install-ssh-guaranteed-on-sd.sh` + User Creation

**Steps:**
1. Run `install-ssh-guaranteed-on-sd.sh` to install SSH services
2. Run `create-user-boot-script.sh` to create user creation script
3. Ensure `ssh-activate.sh` calls `create-user-on-boot.sh`
4. Verify all files are in place
5. Boot and test

**Why this works:**
- Multiple layers (flag, service, watchdog, rc.local)
- Continuous monitoring (watchdog)
- User creation included
- Comprehensive error handling

### For Custom Builds

**Include in build:**
1. `first-boot-setup.service` - Creates user once
2. `ssh-guaranteed.service` - Multi-layer SSH activation
3. `ssh-watchdog.service` - Continuous monitoring
4. `rc.local` - Fallback

**Why this works:**
- All layers together
- User created automatically
- SSH enabled automatically
- Continuous monitoring

---

## 11. Testing and Verification

### Pre-Boot Verification

**Script:** `verify-ssh-installation.sh`

**Checks:**
- SSH flag file exists
- SSH activation script exists and is executable
- Systemd service files are installed (if rootfs available)
- rc.local exists and is executable (if rootfs available)
- Permissions are correct

**Status:** ✅ **WORKS** - Can verify before boot

### Post-Boot Testing

**Script:** `test-ssh-after-boot.sh`

**Checks:**
- SSH connection works
- SSH service is running
- SSH service is enabled
- Port 22 is listening
- SSH keys exist
- Services are active

**Status:** ✅ **WORKS** - Can test after boot

---

## 12. Known Issues and Solutions

### Issue 1: User Doesn't Exist

**Problem:** User "andre" doesn't exist after boot

**Cause:** User creation script didn't run

**Solution:**
- Check if script exists on boot partition
- Check if rc.local calls the script
- Check if script has execute permissions
- Manually run script: `sudo /boot/firmware/create-user-on-boot.sh`

### Issue 2: SSH Service Not Running

**Problem:** SSH service is not running after boot

**Cause:** Service didn't start or was disabled

**Solution:**
- Check service status: `systemctl status ssh`
- Check service logs: `journalctl -u ssh`
- Manually start: `sudo systemctl start ssh`
- Check if watchdog is running: `systemctl status ssh-watchdog`

### Issue 3: SSH Port Not Listening

**Problem:** Port 22 is not listening

**Cause:** SSH service not started or blocked

**Solution:**
- Check if SSH service is running
- Check firewall rules
- Check SSH config: `cat /etc/ssh/sshd_config`
- Restart SSH: `sudo systemctl restart ssh`

### Issue 4: Authentication Fails

**Problem:** SSH connection fails with authentication error

**Cause:** User doesn't exist or password is wrong

**Solution:**
- Check if user exists: `cat /etc/passwd | grep andre`
- Check password: Try different password
- Create user manually if needed
- Check SSH config allows password auth

---

## 13. Files Reference

### Installation Scripts

- `ENABLE_SSH_MOODE_STANDARD.sh` - Simple flag file only
- `INSTALL_INDEPENDENT_SSH.sh` - Medium complexity with systemd service
- `install-ssh-guaranteed-on-sd.sh` - Comprehensive with watchdog
- `install-independent-ssh-sd-card.sh` - Most robust with best error handling
- `create-user-boot-script.sh` - Creates user creation script on boot partition

### Systemd Services

- `moode-source/lib/systemd/system/ssh-asap.service` - Earliest SSH start
- `moode-source/lib/systemd/system/ssh-guaranteed.service` - Multi-layer SSH activation
- `moode-source/lib/systemd/system/ssh-watchdog.service` - Continuous monitoring
- `moode-source/lib/systemd/system/ssh-ultra-early.service` - Ultra early SSH
- `moode-source/lib/systemd/system/first-boot-setup.service` - First boot setup

### Scripts

- `moode-source/usr/local/bin/first-boot-setup.sh` - First boot setup script
- `moode-source/usr/local/bin/force-ssh-on.sh` - Aggressive SSH enabling
- `moode-source/usr/local/bin/create-user-on-boot.sh` - User creation script

### Testing Scripts

- `verify-ssh-installation.sh` - Pre-boot verification
- `test-ssh-after-boot.sh` - Post-boot testing

---

## 14. Next Steps

### Immediate Actions

1. **Check SD card status** - Verify what's currently on the SD card
2. **Run verification script** - Check if files are in place
3. **Install missing components** - Add any missing services or scripts
4. **Test after boot** - Boot Pi and test SSH connection

### Long-term Solutions

1. **Build custom image** - Include all SSH services in build
2. **Test thoroughly** - Verify SSH works reliably
3. **Document working solution** - Create definitive guide
4. **Automate testing** - Create test suite that runs automatically

---

## 15. Conclusion

**Current Status:**
- Multiple SSH installation scripts exist
- Multiple systemd services exist
- User creation scripts exist
- Testing scripts exist
- **BUT:** Nothing has been fully tested and verified

**What's Needed:**
- Comprehensive testing of all approaches
- Verification that SSH actually works after boot
- Documentation of what actually works
- Reliable, tested solution

**Recommendation:**
- Use `install-ssh-guaranteed-on-sd.sh` + `create-user-boot-script.sh`
- Verify all files are in place
- Boot and test
- Document results

---

**Last Updated:** 2024-12-29  
**Status:** Knowledge base created, needs testing and verification

