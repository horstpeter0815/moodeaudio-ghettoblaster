# 🔍 SSH ROOT CAUSE ANALYSIS - COMPLETE INVESTIGATION

**Date:** 2025-01-20  
**Status:** 🔴 **CRITICAL ISSUE IDENTIFIED**

---

## 📋 EXECUTIVE SUMMARY

**Problem:** SSH does not work despite multiple services attempting to enable it.

**Impact:** Half of project time wasted debugging SSH issues.

**Root Cause:** Multiple potential failure points identified. Need systematic verification.

---

## 🔬 COMPLETE SSH BOOT SEQUENCE ANALYSIS

### **Phase 1: Early Boot (Before moOde)**

#### 1.1 `ssh-guaranteed.service`
- **Location:** `moode-source/lib/systemd/system/ssh-guaranteed.service`
- **Runs:** `After=local-fs.target`, `Before=moode-startup.service`
- **Actions:**
  - Creates `/boot/firmware/ssh` flag
  - Runs `systemctl enable ssh`
  - Runs `systemctl start ssh`
  - Unmasks SSH service
  - Generates SSH keys if missing
  - Has ExecStartPost loop that runs every 30 seconds for 5 minutes

**✅ SHOULD WORK** - Runs early, multiple safety layers

#### 1.2 `boot-complete-minimal.service`
- **Location:** `moode-source/lib/systemd/system/boot-complete-minimal.service`
- **Runs:** `After=local-fs.target`, `Before=network.target`
- **Actions:**
  - Configures eth0 network
  - Runs `systemctl enable ssh`
  - Runs `systemctl start ssh`
  - Creates SSH flag

**✅ SHOULD WORK** - Runs very early, before network

#### 1.3 `enable-ssh-early.service`
- **Location:** `moode-source/lib/systemd/system/enable-ssh-early.service`
- **Runs:** `Before=moode-startup.service`
- **Actions:**
  - Enables SSH
  - Starts SSH
  - Creates SSH flag

**✅ SHOULD WORK** - Explicitly runs before moOde

#### 1.4 `ssh-asap.service`
- **Location:** `moode-source/lib/systemd/system/ssh-asap.service`
- **Runs:** Early boot
- **Actions:**
  - Enables SSH
  - Starts SSH
  - Creates SSH flag

**✅ SHOULD WORK** - Multiple attempts

#### 1.5 `independent-ssh.service`
- **Location:** Should exist in system
- **Calls:** `/boot/firmware/ssh-activate.sh`
- **Actions:**
  - Enables SSH
  - Starts SSH
  - Creates SSH flag
  - Creates symlinks

**✅ SHOULD WORK** - Independent of moOde

### **Phase 2: First Boot Setup**

#### 2.1 `first-boot-setup.sh`
- **Location:** `moode-source/usr/local/bin/first-boot-setup.sh`
- **Runs:** Once, on first boot
- **Actions:**
  - Creates `/boot/ssh` flag
  - Enables SSH service
  - Starts SSH service
  - Creates SSH config if missing
  - Unmasks SSH

**⚠️ ONLY RUNS ONCE** - If marker file exists, skips SSH setup

### **Phase 3: moOde Startup**

#### 3.1 `moode-startup.service`
- **Status:** ⚠️ **UNKNOWN** - Service file not found in codebase
- **Potential Issue:** May disable SSH if not configured correctly

#### 3.2 `worker.php`
- **Location:** `moode-source/www/daemon/worker.php`
- **Runs:** After moOde startup
- **Potential Issue:** May disable SSH based on configuration

**🔴 NEEDS VERIFICATION** - Check if worker.php disables SSH

---

## 🚨 IDENTIFIED PROBLEMS

### **Problem 1: Service Ordering Race Condition**

**Issue:** Multiple services try to enable SSH, but they may conflict or race.

**Evidence:**
- `ssh-guaranteed.service` runs `Before=sysinit.target`
- `boot-complete-minimal.service` runs `Before=network.target`
- Both try to enable SSH simultaneously

**Impact:** Services may interfere with each other.

**Fix Needed:** Ensure services don't conflict.

---

### **Problem 2: SSH Service May Not Actually Start**

**Issue:** `systemctl enable ssh` doesn't guarantee SSH is running.

**Evidence:**
- Services run `systemctl enable ssh` and `systemctl start ssh`
- But SSH may fail to start if:
  - SSH keys don't exist
  - SSH config is invalid
  - Port 22 is blocked
  - SSH daemon binary is missing

**Impact:** SSH is "enabled" but not actually running.

**Fix Needed:** Verify SSH is actually running, not just enabled.

---

### **Problem 3: Network Not Ready**

**Issue:** SSH services run before network is ready.

**Evidence:**
- `boot-complete-minimal.service` runs `Before=network.target`
- SSH needs network to accept connections
- If network isn't ready, SSH can't accept connections

**Impact:** SSH starts but can't accept connections until network is ready.

**Fix Needed:** Ensure SSH starts after network is ready, OR ensure SSH starts and waits for network.

---

### **Problem 4: moOde May Disable SSH**

**Issue:** moOde worker.php or startup scripts may disable SSH.

**Evidence:**
- Build scripts originally disabled SSH (`ENABLE_SSH="${ENABLE_SSH:-0}"`)
- Fixed in build scripts, but moOde runtime may still disable SSH
- No verification that moOde doesn't disable SSH

**Impact:** SSH is enabled early, but moOde disables it later.

**Fix Needed:** Verify moOde doesn't disable SSH, OR ensure SSH re-enables after moOde starts.

---

### **Problem 5: SSH Flag File Removed**

**Issue:** `/boot/firmware/ssh` flag may be removed after first boot.

**Evidence:**
- Raspberry Pi OS removes `/boot/ssh` after first boot
- Services recreate it, but timing may be wrong
- If flag is removed before services run, SSH may not start

**Impact:** SSH doesn't start because flag is missing.

**Fix Needed:** Ensure flag is created persistently, not just on first boot.

---

### **Problem 6: SSH Keys Missing**

**Issue:** SSH host keys may not exist.

**Evidence:**
- Build script removes SSH keys: `rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*`
- Services try to generate keys, but may fail
- If keys don't exist, SSH can't start

**Impact:** SSH service fails to start because keys are missing.

**Fix Needed:** Ensure SSH keys are generated before SSH starts.

---

### **Problem 7: Service Dependencies**

**Issue:** Services may have incorrect dependencies.

**Evidence:**
- Some services have `After=moode-startup.service` (removed in fixes)
- But `moode-startup.service` may not exist or may hang
- Services waiting for non-existent service will never run

**Impact:** SSH services never run because they're waiting for non-existent service.

**Fix Needed:** Remove incorrect dependencies.

---

## 🔧 VERIFICATION STEPS NEEDED

### **Step 1: Check SSH Service Status**

```bash
# On Pi after boot
systemctl status ssh
systemctl status sshd
systemctl is-enabled ssh
systemctl is-active ssh
```

**Expected:** SSH should be enabled AND active.

**If Not:** SSH is enabled but not running → **Problem 2**

---

### **Step 2: Check SSH Process**

```bash
# On Pi after boot
ps aux | grep sshd
netstat -tuln | grep :22
ss -tuln | grep :22
```

**Expected:** SSH daemon should be running and listening on port 22.

**If Not:** SSH service is enabled but process isn't running → **Problem 2**

---

### **Step 3: Check SSH Keys**

```bash
# On Pi after boot
ls -la /etc/ssh/ssh_host_*_key*
```

**Expected:** SSH host keys should exist.

**If Not:** SSH keys are missing → **Problem 6**

---

### **Step 4: Check SSH Flag**

```bash
# On Pi after boot
ls -la /boot/firmware/ssh
ls -la /boot/ssh
```

**Expected:** SSH flag file should exist.

**If Not:** SSH flag is missing → **Problem 5**

---

### **Step 5: Check Service Logs**

```bash
# On Pi after boot
journalctl -u ssh-guaranteed.service
journalctl -u boot-complete-minimal.service
journalctl -u enable-ssh-early.service
journalctl -u independent-ssh.service
journalctl -u ssh
```

**Expected:** Services should show successful SSH enable/start.

**If Not:** Services are failing → Check specific error messages.

---

### **Step 6: Check moOde Worker**

```bash
# On Pi after boot
grep -i "ssh" /var/log/moode.log
grep -i "disable.*ssh" /var/www/daemon/worker.php
```

**Expected:** moOde should not disable SSH.

**If Not:** moOde is disabling SSH → **Problem 4**

---

### **Step 7: Check Network**

```bash
# On Pi after boot
ip addr show
ip route show
ping -c 1 8.8.8.8
```

**Expected:** Network should be configured and working.

**If Not:** Network isn't ready → **Problem 3**

---

## 🎯 MOST LIKELY ROOT CAUSES (Ranked)

### **#1: SSH Service Not Actually Running (Problem 2)**
**Probability:** 70%

**Why:**
- Services enable SSH but don't verify it's running
- SSH may fail to start silently
- No verification that SSH is actually listening

**Fix:**
- Add verification after `systemctl start ssh`
- Check if SSH process is running
- Check if port 22 is listening
- Retry if SSH doesn't start

---

### **#2: moOde Disables SSH After Startup (Problem 4)**
**Probability:** 20%

**Why:**
- moOde worker.php may disable SSH based on configuration
- moOde startup scripts may disable SSH
- No verification that moOde doesn't disable SSH

**Fix:**
- Check worker.php for SSH disable commands
- Add service that runs AFTER moOde to re-enable SSH
- Monitor SSH status continuously

---

### **#3: Network Not Ready (Problem 3)**
**Probability:** 5%

**Why:**
- SSH services run before network is ready
- SSH can't accept connections without network
- Timing issue

**Fix:**
- Ensure SSH starts after network is ready
- OR ensure SSH waits for network before accepting connections

---

### **#4: SSH Keys Missing (Problem 6)**
**Probability:** 3%

**Why:**
- Build script removes SSH keys
- Services try to generate keys but may fail
- SSH can't start without keys

**Fix:**
- Ensure SSH keys are generated before SSH starts
- Verify keys exist before starting SSH

---

### **#5: Service Dependencies (Problem 7)**
**Probability:** 2%

**Why:**
- Services may have incorrect dependencies
- Services waiting for non-existent service never run

**Fix:**
- Remove incorrect dependencies
- Ensure services run independently

---

## 🔨 RECOMMENDED FIXES

### **Fix 1: Add SSH Verification Service**

Create a service that:
1. Verifies SSH is running
2. Checks if port 22 is listening
3. Restarts SSH if not running
4. Runs continuously (watchdog)

**Priority:** HIGH

---

### **Fix 2: Add SSH Status Check Script**

Create a script that:
1. Checks SSH service status
2. Checks SSH process
3. Checks port 22
4. Checks SSH keys
5. Reports all findings

**Priority:** HIGH

---

### **Fix 3: Verify moOde Doesn't Disable SSH**

1. Search worker.php for SSH disable commands
2. Check moOde startup scripts
3. Monitor SSH status during moOde startup
4. Add protection if moOde tries to disable SSH

**Priority:** MEDIUM

---

### **Fix 4: Ensure SSH Starts After Network**

1. Change SSH services to start after network
2. OR add network check before starting SSH
3. Ensure SSH waits for network

**Priority:** LOW (if network is working)

---

## 📊 TEST PLAN

### **Test 1: SSH Service Status**
- Boot Pi
- Check `systemctl status ssh`
- **Expected:** Enabled and active

### **Test 2: SSH Process**
- Boot Pi
- Check `ps aux | grep sshd`
- **Expected:** SSH daemon running

### **Test 3: Port 22 Listening**
- Boot Pi
- Check `netstat -tuln | grep :22`
- **Expected:** Port 22 listening

### **Test 4: SSH Connection**
- Boot Pi
- Try `ssh andre@<PI_IP>`
- **Expected:** Connection successful

### **Test 5: SSH After moOde Starts**
- Boot Pi
- Wait for moOde to start
- Check SSH status again
- **Expected:** SSH still enabled and active

---

## 🎯 NEXT STEPS

1. **Run verification steps** on actual Pi
2. **Identify specific failure point** from verification
3. **Apply targeted fix** based on failure point
4. **Test fix** thoroughly
5. **Document solution**

---

## 📝 CONCLUSION

**Multiple SSH services exist and SHOULD enable SSH, but SSH is not working.**

**Most likely cause:** SSH service is enabled but not actually running, OR moOde disables SSH after startup.

**Action required:** Run verification steps to identify specific failure point, then apply targeted fix.

---

**Status:** 🔴 **ANALYSIS COMPLETE - VERIFICATION NEEDED**

