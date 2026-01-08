# SSH Installation Scripts - Testing Guide

## Testing Status

**Note:** Actual hardware testing requires a Raspberry Pi with moOde Audio installed. This guide provides the testing procedures to follow.

## Testing Prerequisites

1. **Hardware:**
   - Raspberry Pi 4 or Pi 5
   - SD card with standard moOde Audio image
   - Mac computer for SD card modification
   - Network connection

2. **Software:**
   - All SSH installation scripts
   - Verification script: `verify-ssh-installation.sh`
   - Test script: `test-ssh-after-boot.sh`
   - sshpass (for automated password entry)

## Testing Procedure

### Test 1: ENABLE_SSH_MOODE_STANDARD.sh

**Purpose:** Test simple flag file method

**Steps:**
1. Flash fresh moOde image to SD card
2. Insert SD card into Mac
3. Run: `./ENABLE_SSH_MOODE_STANDARD.sh`
4. Verify: `./verify-ssh-installation.sh`
5. Eject SD card and boot Pi
6. Wait 60 seconds
7. Test: `./test-ssh-after-boot.sh [PI_IP] [USER] [PASSWORD]`

**Expected Results:**
- ✅ SSH flag file created
- ✅ SSH works after boot
- ⚠️ SSH may be disabled by moOde later

**Success Criteria:**
- SSH connection works within 60 seconds of boot
- Can login via SSH

---

### Test 2: INSTALL_INDEPENDENT_SSH.sh

**Purpose:** Test medium complexity with systemd service

**Steps:**
1. Flash fresh moOde image to SD card
2. Insert SD card into Mac
3. Run: `./INSTALL_INDEPENDENT_SSH.sh`
4. Verify: `./verify-ssh-installation.sh`
5. Eject SD card and boot Pi
6. Wait 60 seconds
7. Test: `./test-ssh-after-boot.sh [PI_IP] [USER] [PASSWORD]`

**Expected Results:**
- ✅ SSH flag file created
- ✅ Activation script created
- ✅ Systemd service installed (if rootfs available)
- ✅ rc.local created (if rootfs available)
- ✅ SSH works after boot
- ✅ SSH survives moOde configuration changes

**Success Criteria:**
- SSH connection works within 60 seconds of boot
- SSH service is running
- SSH service is enabled
- Independent service is active

---

### Test 3: install-ssh-guaranteed-on-sd.sh

**Purpose:** Test comprehensive solution with watchdog

**Steps:**
1. Flash fresh moOde image to SD card
2. Insert SD card into Mac
3. Run: `./install-ssh-guaranteed-on-sd.sh`
4. Verify: `./verify-ssh-installation.sh`
5. Eject SD card and boot Pi
6. Wait 60 seconds
7. Test: `./test-ssh-after-boot.sh [PI_IP] [USER] [PASSWORD]`

**Expected Results:**
- ✅ SSH flag file created
- ✅ Systemd service installed (if rootfs available)
- ✅ Watchdog service installed (if rootfs available)
- ✅ rc.local created (if rootfs available)
- ✅ SSH works after boot
- ✅ SSH survives moOde configuration changes
- ✅ Watchdog monitors SSH continuously

**Success Criteria:**
- SSH connection works within 60 seconds of boot
- SSH service is running
- SSH service is enabled
- Watchdog service is active
- SSH restarts automatically if stopped

**Additional Test:**
- Manually stop SSH: `sudo systemctl stop ssh`
- Wait 30 seconds
- Verify SSH restarts automatically (watchdog should restart it)

---

### Test 4: install-independent-ssh-sd-card.sh (Recommended)

**Purpose:** Test most robust solution

**Steps:**
1. Flash fresh moOde image to SD card
2. Insert SD card into Mac
3. Run: `./install-independent-ssh-sd-card.sh`
4. Verify: `./verify-ssh-installation.sh`
5. Eject SD card and boot Pi
6. Wait 60 seconds
7. Test: `./test-ssh-after-boot.sh [PI_IP] [USER] [PASSWORD]`

**Expected Results:**
- ✅ SSH flag file created (with robust error handling)
- ✅ Activation script created
- ✅ Systemd service installed (if rootfs available)
- ✅ rc.local created (if rootfs available)
- ✅ All files verified
- ✅ SSH works after boot
- ✅ SSH survives moOde configuration changes

**Success Criteria:**
- SSH connection works within 60 seconds of boot
- SSH service is running
- SSH service is enabled
- Independent service is active
- All verification checks pass

---

## Test Scenarios

### Scenario 1: Fresh moOde Installation

**Test:** Install SSH on brand new moOde image

**Expected:** All scripts should work

---

### Scenario 2: Rootfs Not Available

**Test:** Install SSH when rootfs partition is not mounted

**Expected:**
- SSH flag file should be created
- Services will be created on first boot
- SSH should still work

---

### Scenario 3: SSH Disabled by moOde

**Test:** After SSH is working, change moOde configuration

**Expected:**
- Scripts with systemd services: SSH should remain enabled
- Simple flag file script: SSH may be disabled

---

### Scenario 4: Network Delay

**Test:** Boot Pi with network cable unplugged, then plug in

**Expected:**
- SSH should work once network is available
- Watchdog should ensure SSH starts when network is ready

---

### Scenario 5: Multiple Boots

**Test:** Boot Pi multiple times

**Expected:**
- SSH should work on every boot
- Services should start consistently
- No degradation over time

---

## Test Results Template

```
Test Date: [DATE]
Script: [SCRIPT_NAME]
Pi Model: [Pi 4 / Pi 5]
moOde Version: [VERSION]

Pre-Boot Verification:
- SSH flag file: [PASS/FAIL]
- Activation script: [PASS/FAIL]
- Systemd service: [PASS/FAIL]
- rc.local: [PASS/FAIL]

Post-Boot Testing:
- SSH connection: [PASS/FAIL]
- SSH service running: [PASS/FAIL]
- SSH service enabled: [PASS/FAIL]
- Port 22 listening: [PASS/FAIL]
- SSH keys exist: [PASS/FAIL]

Time to SSH Available: [SECONDS]

Issues Found:
[LIST ANY ISSUES]

Overall Result: [PASS/FAIL]
```

---

## Automated Testing

### Quick Test Script

Create a script to test all methods:

```bash
#!/bin/bash
# test-all-ssh-scripts.sh

SCRIPTS=(
    "ENABLE_SSH_MOODE_STANDARD.sh"
    "INSTALL_INDEPENDENT_SSH.sh"
    "install-ssh-guaranteed-on-sd.sh"
    "install-independent-ssh-sd-card.sh"
)

for script in "${SCRIPTS[@]}"; do
    echo "Testing: $script"
    # Flash fresh image
    # Run script
    # Verify
    # Boot and test
    # Document results
done
```

---

## Known Limitations

1. **Hardware Required:** Testing requires actual Raspberry Pi hardware
2. **Time Consuming:** Each test requires flashing image and booting Pi
3. **Network Dependent:** Tests require network connectivity
4. **User Dependent:** Requires correct username/password

---

## Recommendations for Testing

1. **Start with recommended script:** `install-independent-ssh-sd-card.sh`
2. **Use verification script:** Always verify before boot
3. **Use test script:** Always test after boot
4. **Document results:** Keep track of what works
5. **Test edge cases:** Rootfs not available, network issues, etc.

---

## Next Steps

1. **Perform actual hardware testing** when Pi is available
2. **Document test results** in this file
3. **Update recommendations** based on test results
4. **Fix any issues** found during testing

---

**Status:** Testing procedures documented, awaiting hardware testing  
**Last Updated:** 2025-01-09

